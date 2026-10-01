import fastify from 'fastify';
import fastifyCors from '@fastify/cors';
import fastifyWebsocket from '@fastify/websocket';
import { PrismaClient } from '@prisma/client';
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
import protobuf from 'protobufjs';
import path from 'path';

dotenv.config();

const server = fastify({ logger: true });
const prisma = new PrismaClient();

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-key-do-not-use-in-prod';

// Load Protobuf Schema
const protoPath = path.resolve(__dirname, '../proto/transmission.proto');
const protoRoot = protobuf.loadSync(protoPath);
const TransceiverPacket = protoRoot.lookupType('itantra.v1.TransceiverPacket');

server.register(fastifyCors, {
  origin: '*',
});

server.register(fastifyWebsocket);

// 3.1 GET /api/healthz
server.get('/api/healthz', async (request, reply) => {
  return {
    status: 'HEALTHY',
    timestamp: new Date().toISOString(),
    services: {
      c2Portal: 'UP',
      streamGateway: 'UP',
      database: 'UP',
    }
  };
});

// 2.2 POST /api/v1/auth/device-register
server.post('/api/v1/auth/device-register', async (request, reply) => {
  const { callsign, deviceId, deviceFingerprint, unitType } = request.body as any;
  
  if (!callsign || !deviceId || !deviceFingerprint) {
    return reply.status(400).send({ error: 'Missing required fields' });
  }

  // Create or update device
  const device = await prisma.device.upsert({
    where: { callsign },
    update: { deviceId, deviceFingerprint, isActive: true },
    create: { callsign, deviceId, deviceFingerprint, unitType: unitType || 'FIELD_TRANSCEIVER' }
  });

  return reply.status(201).send({
    registered: true,
    callsign: device.callsign,
    deviceId: device.deviceId
  });
});

// 2.2 POST /api/v1/auth/token
server.post('/api/v1/auth/token', async (request, reply) => {
  const { callsign, deviceId, deviceFingerprint } = request.body as any;

  const device = await prisma.device.findUnique({ where: { callsign } });
  
  if (!device || device.deviceId !== deviceId || device.deviceFingerprint !== deviceFingerprint) {
    return reply.status(401).send({ error: 'Invalid credentials or unverified hardware signature' });
  }

  const token = jwt.sign(
    { callsign, deviceId }, 
    JWT_SECRET, 
    { expiresIn: '24h' }
  );

  const expiresAt = new Date();
  expiresAt.setHours(expiresAt.getHours() + 24);

  return {
    token,
    expiresAt: expiresAt.toISOString(),
    callsign
  };
});

// 3.2 GET /api/v1/channels
server.get('/api/v1/channels', async (request, reply) => {
  const channels = await prisma.channel.findMany();
  return { channels };
});

// 3.3 GET /api/v1/channels/{channelId}/messages
server.get('/api/v1/channels/:channelId/messages', async (request, reply) => {
  const { channelId } = request.params as any;
  const { limit = 50, since } = request.query as any;

  const whereClause: any = { channelId };
  if (since) {
    whereClause.timestamp = { gt: new Date(parseInt(since)) };
  }

  const messages = await prisma.transmission.findMany({
    where: whereClause,
    take: parseInt(limit),
    orderBy: { timestamp: 'desc' }
  });

  return {
    channelId,
    messages,
    hasMore: messages.length === parseInt(limit),
    nextSince: messages.length > 0 ? messages[messages.length - 1].timestamp.getTime() : null
  };
});

// 3.4 GET /api/v1/incidents/active
server.get('/api/v1/incidents/active', async (request, reply) => {
  const activeIncidents = await prisma.emergencyIncident.findMany({
    where: { isActive: true },
    orderBy: { declaredAt: 'desc' }
  });
  return { incidents: activeIncidents };
});

// Offline Backlog Sync
server.post('/api/v1/transmissions/sync', async (request, reply) => {
  const { packets } = request.body as any;
  
  if (!Array.isArray(packets)) {
    return reply.status(400).send({ error: 'Packets must be an array' });
  }

  const creations = packets.map(p => prisma.transmission.upsert({
    where: { packetId: p.packetId },
    update: {},
    create: {
      packetId: p.packetId,
      senderCallsign: p.senderCallsign,
      recipientCallsign: p.recipientCallsign,
      channelId: p.channelId,
      compactTextPayload: p.compactTextPayload,
      priority: p.priority,
      transportUsed: p.transportUsed,
      timestamp: new Date(p.timestampEpochMs || Date.now()),
      latitude: p.location?.latitude,
      longitude: p.location?.longitude,
    }
  }));

  await prisma.$transaction(creations);

  return reply.status(200).send({ syncedCount: packets.length });
});

// Priority 5: AI Model Hub & OTA Distribution
server.get('/api/v1/models', async (request, reply) => {
  // In a real scenario, this fetches from S3 or MinIO and generates Presigned URLs.
  // We provide the static manifest for the Android app to download models dynamically.
  return {
    models: [
      {
        id: 'whisper-cpp-tiny-int8',
        type: 'STT',
        language: 'MULTILINGUAL',
        sizeBytes: 42000000,
        sha256: 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2',
        downloadUrl: 'https://cdn.itantra.org/models/whisper-tiny-int8.bin',
        version: '1.0.0'
      },
      {
        id: 'piper-tts-hi-in',
        type: 'TTS',
        language: 'hi-IN',
        sizeBytes: 15000000,
        sha256: 'b1c2d3e4f5g6h7i8j9k0l1m2n3o4p5q6r7s8t9u0v1w2x3y4z5a6b7c8d9e0f1a2',
        downloadUrl: 'https://cdn.itantra.org/models/piper-hi-in.onnx',
        version: '1.0.0'
      }
    ]
  };
});

// WebSocket Stream Gateway
server.register(async function (fastify) {
  fastify.get('/v1/transceiver/channel', { websocket: true }, (connection, req) => {
    connection.socket.on('message', async (message: Buffer) => {
      try {
        // Attempt to decode as Protobuf
        const packet = TransceiverPacket.decode(message);
        fastify.log.info(`[Protobuf WS] Received packet: ${packet.packet_id} from ${packet.sender_callsign}`);
        
        // Log the payload details
        fastify.log.info(JSON.stringify(packet, null, 2));

        // TODO: In a production cluster, push this to NATS JetStream for pub/sub routing
        // For now, we simply acknowledge receipt using the same binary format
        const outBuffer = TransceiverPacket.encode(packet).finish();
        connection.socket.send(outBuffer);
      } catch (err) {
        fastify.log.error(`[WS Error] Failed to decode Protobuf payload: ${err}`);
      }
    });
  });
});

const start = async () => {
  try {
    await server.listen({ port: 3000, host: '0.0.0.0' });
    console.log(`Server listening on http://localhost:3000`);
    console.log(`WebSocket listening on ws://localhost:3000/v1/transceiver/channel`);
  } catch (err) {
    server.log.error(err);
    process.exit(1);
  }
};

start();
