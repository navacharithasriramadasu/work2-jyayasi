# iTantra C2 Backend — Implementation Specification

> **Document Version:** 1.0 — September 2026
> **Generated From:** iTantra Flutter App Live Integration Code (`lib/services/api/`, `lib/services/websocket/`, `lib/core/config/`)
> **Target Audience:** Backend Engineering Team
> **Status:** ?? Auth Endpoint Missing · ?? WS Schema Undefined · ?? Model Binaries Not Staged

This document defines **exactly what the Flutter app expects** from the backend — derived directly from the production integration code. Every request shape, response shape, and WebSocket event schema listed here is what the app is already sending or parsing right now.

---

## Table of Contents

1. [Base URLs & Environments](#1-base-urls--environments)
2. [Authentication](#2-authentication)
3. [REST API Contracts](#3-rest-api-contracts)
4. [WebSocket Gateway Contract](#4-websocket-gateway-contract)
5. [Database Schema Requirements](#5-database-schema-requirements)
6. [Prioritized Action Items](#6-prioritized-action-items)
7. [Error Response Standard](#7-error-response-standard)

---

## 1. Base URLs & Environments

| Environment | REST Base URL | WebSocket URL |
|---|---|---|
| **Production** | `https://itantra-c2-portal.onrender.com` | `wss://itantra-stream-gateway.onrender.com/v1/transceiver/channel` |
| **Android Emulator** | `http://10.0.2.2:3000` | `ws://10.0.2.2:8443/v1/transceiver/channel` |
| **LAN (Physical Device)** | `http://<SERVER_IP>:3000` | `ws://<SERVER_IP>:8443/v1/transceiver/channel` |
| **Field Edge (K3s/RPi)** | `http://192.168.10.1:3000` | `ws://192.168.10.1:8443/v1/transceiver/channel` |
| **Custom Domain** | `https://c2.itantra.org` | `wss://stream.itantra.org/v1/transceiver/channel` |

---

## 2. Authentication

### 2.1 Required HTTP Headers

Every non-health API call from the Flutter app sends:

```
Content-Type: application/json
Authorization: Bearer <TOKEN>
x-transceiver-callsign: <CALLSIGN>
```

### 2.2 ?? MISSING: Token Issuance Endpoints

#### POST /api/v1/auth/token

Request:
```json
{
  "callsign": "ALPHA-1",
  "deviceId": "dev-alpha-001-node",
  "deviceFingerprint": "sha256:<android_device_fingerprint>"
}
```

Response 200:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresAt": "2026-09-28T04:36:03Z",
  "callsign": "ALPHA-1"
}
```

#### POST /api/v1/auth/device-register

Request:
```json
{
  "callsign": "ALPHA-1",
  "deviceId": "dev-alpha-001-node",
  "deviceFingerprint": "sha256:<fingerprint>",
  "unitType": "FIELD_TRANSCEIVER"
}
```

Response 201:
```json
{
  "registered": true,
  "callsign": "ALPHA-1",
  "deviceId": "dev-alpha-001-node"
}
```

#### POST /api/v1/auth/refresh

Request:
```json
{ "token": "<EXISTING_BEARER_TOKEN>" }
```

Response 200:
```json
{ "token": "<NEW_BEARER_TOKEN>", "expiresAt": "2026-09-28T10:36:03Z" }
```

> **For Staging/Dev:** Until the device registration flow is complete, provide a static staging Bearer token value that can be configured by the Flutter team in ApiConfig.bearerToken.

---

## 3. REST API Contracts

### 3.1 GET /api/healthz

No auth required.

Response 200:
```json
{
  "status": "HEALTHY",
  "timestamp": "2026-09-27T22:36:03Z",
  "services": {
    "c2Portal": "UP",
    "streamGateway": "UP",
    "database": "UP",
    "nats": "UP"
  }
}
```

Flutter checks: `data['status'] == 'HEALTHY'`

---

### 3.2 GET /api/v1/channels

Auth required.

Response 200:
```json
{
  "channels": [
    {
      "channelId": "chan-cmd-net-02",
      "name": "COMMAND_NET",
      "description": "Primary command and control network",
      "frequencyMhz": 434.25,
      "isEncrypted": true,
      "activeSubscribers": 4
    },
    {
      "channelId": "chan-emergency-01",
      "name": "EMERGENCY_BROADCAST",
      "description": "Emergency and SOS broadcast channel",
      "frequencyMhz": 433.175,
      "isEncrypted": false,
      "activeSubscribers": 12
    }
  ]
}
```

Flutter field mappings: `channelId` (also accepts `id`), `name` (also accepts `channelName`), `activeSubscribers` (also accepts `activeMembers`).

---

### 3.3 GET /api/v1/channels/{channelId}/messages

Auth required.

Query Parameters:
- `limit` (integer, default 50)
- `since` (epoch milliseconds, optional)

Response 200:
```json
{
  "channelId": "chan-cmd-net-02",
  "messages": [
    {
      "packetId": "pkt-uuid-0001",
      "senderCallsign": "BRAVO-3",
      "recipientCallsign": "BROADCAST_ALL",
      "channelId": "chan-cmd-net-02",
      "compactTextPayload": "Sector 4 is clear. Proceeding to extraction point.",
      "priority": "PRIORITY_ROUTINE",
      "transportUsed": "WIFI_DIRECT",
      "timestamp": 1727467563000,
      "latitude": 17.3850,
      "longitude": 78.4867
    }
  ],
  "hasMore": false,
  "nextSince": null
}
```

Flutter field mappings: `senderCallsign`, `compactTextPayload`, `priority`, `transportUsed`, `packetId`, `recipientCallsign`.

---

### 3.4 GET /api/v1/incidents/active

Auth required.

Response 200:
```json
{
  "incidents": [
    {
      "incidentId": "inc-uuid-0001",
      "packetId": "pkt-uuid-sos-001",
      "initiatingCallsign": "DELTA-7",
      "alertType": "CRITICAL_SOS_BROADCAST",
      "status": "ACTIVE_DISPATCH",
      "firstResponderAssigned": "ALPHA-1",
      "createdAt": "2026-09-27T20:15:00Z",
      "resolvedAt": null
    }
  ]
}
```

status values: ACTIVE_DISPATCH | FIRST_RESPONDER_ASSIGNED | RESOLVED | CANCELLED
alertType values: CRITICAL_SOS_BROADCAST | MEDICAL_EMERGENCY | STRUCTURAL_HAZARD

---

### 3.5 POST /api/v1/ingest

Auth required.

Request:
```json
{
  "packetId": "msg-1727467563-abc123",
  "senderCallsign": "ALPHA-1",
  "recipientCallsign": "BROADCAST_ALL",
  "channelId": "chan-cmd-net-02",
  "compactTextPayload": "Requesting status update from Sector 4.",
  "priority": "PRIORITY_ROUTINE",
  "transportUsed": "WIFI_DIRECT",
  "timestamp": 1727467563000,
  "latitude": 17.3850,
  "longitude": 78.4867
}
```

priority values: PRIORITY_ROUTINE | PRIORITY_EMERGENCY_SOS
transportUsed values: WIFI_DIRECT | BLUETOOTH_LE | LORA | LTE | SATCOM

Response 201:
```json
{
  "success": true,
  "packetId": "msg-1727467563-abc123",
  "acknowledgedAt": "2026-09-27T22:36:03Z"
}
```

---

### 3.6 POST /api/v1/sos

Auth required.

Request:
```json
{
  "packetId": "sos-1727467563-xyz789",
  "senderCallsign": "ALPHA-1",
  "recipientCallsign": "BROADCAST_ALL",
  "channelId": "chan-emergency-01",
  "compactTextPayload": "Structural collapse. Trapped under debris. Grid ref 17.385, 78.486.",
  "priority": "PRIORITY_EMERGENCY_SOS",
  "transportUsed": "WIFI_DIRECT",
  "latitude": 17.3850,
  "longitude": 78.4867
}
```

Response 201:
```json
{
  "success": true,
  "incidentId": "inc-uuid-0001",
  "status": "ACTIVE_DISPATCH",
  "ndmaWebhookDispatched": true
}
```

---

### 3.7 POST /api/v1/telemetry

Auth required.

Request:
```json
{
  "callsign": "ALPHA-1",
  "batteryPercent": 72.5,
  "signalStrengthDbm": -64.0,
  "transportType": "WIFI_DIRECT",
  "latitude": 17.3850,
  "longitude": 78.4867,
  "nodeTemperatureC": 36.5
}
```

Response 200:
```json
{
  "success": true,
  "recordedAt": "2026-09-27T22:36:03Z"
}
```

---

### 3.8 POST /api/v1/transmissions/sync

?? NOT YET IMPLEMENTED. Required for offline-first operation.

Auth required.

Request:
```json
{
  "deviceId": "dev-alpha-001-node",
  "packets": [
    {
      "packetId": "pkt-offline-001",
      "senderCallsign": "ALPHA-1",
      "recipientCallsign": "BRAVO-3",
      "channelId": "chan-cmd-net-02",
      "compactTextPayload": "Offline message captured at 14:32.",
      "priority": "PRIORITY_ROUTINE",
      "transportUsed": "BLUETOOTH_LE",
      "timestamp": 1727455920000,
      "latitude": 17.3900,
      "longitude": 78.4800
    }
  ]
}
```

Response 200:
```json
{
  "success": true,
  "syncedCount": 1,
  "failedCount": 0,
  "duplicatesSkipped": 0
}
```

Business Logic: Packets with duplicate packetId values MUST be idempotently skipped, not rejected.

---

### 3.9 GET /api/v1/models

Auth required.

Response 200:
```json
{
  "models": [
    {
      "id": "whisper-tiny-int8",
      "name": "Whisper Tiny (INT8)",
      "type": "STT",
      "language": "multilingual",
      "sizeBytes": 42700000,
      "sha256": "a1b2c3d4e5f6...",
      "downloadUrl": "/api/v1/models/download/whisper-tiny-int8",
      "version": "1.0.0",
      "isAvailable": true
    },
    {
      "id": "piper-hindi-female",
      "name": "Piper TTS Hindi (Female)",
      "type": "TTS",
      "language": "hi",
      "sizeBytes": 28500000,
      "sha256": "f6e5d4c3b2a1...",
      "downloadUrl": "/api/v1/models/download/piper-hindi-female",
      "version": "1.0.0",
      "isAvailable": true
    }
  ]
}
```

---

### 3.10 GET /api/v1/models/download/{id}

?? Model binaries NOT staged — currently returns 404.

Response: Binary file stream (application/octet-stream).

Required response headers:
```
Content-Length: <file_size_in_bytes>
Accept-Ranges: bytes
Content-Disposition: attachment; filename="whisper-tiny-int8.onnx"
X-SHA256: a1b2c3d4e5f6...
```

MUST support HTTP Range requests (Range: bytes=0-1048576) for resumable downloads on unstable tactical connections.

---

## 4. WebSocket Gateway Contract

Endpoint: wss://itantra-stream-gateway.onrender.com/v1/transceiver/channel

All WebSocket frames are JSON text strings with this envelope:

```json
{
  "event": "<EVENT_NAME>",
  "callsign": "<SENDER_CALLSIGN>",
  "timestamp": 1727467563000,
  "data": { }
}
```

### 4.1 Connection & Authentication

WebSocket Upgrade Request Headers (sent by Flutter app):
```
GET /v1/transceiver/channel HTTP/1.1
Host: itantra-stream-gateway.onrender.com
Upgrade: websocket
Connection: Upgrade
Authorization: Bearer <TOKEN>
x-transceiver-callsign: ALPHA-1
```

If auth fails: Close connection with code 4001 and reason "UNAUTHORIZED".

---

### 4.2 Client ? Server Frames

#### SUBSCRIBE — Join a tactical channel

Sent immediately on connect and on channel switch.

```json
{
  "event": "SUBSCRIBE",
  "callsign": "ALPHA-1",
  "timestamp": 1727467563000,
  "data": { "channelId": "chan-cmd-net-02" }
}
```

Expected server response: TRANSCEIVER_JOINED_CHANNEL event.

---

#### INGEST_PACKET — Send a text transmission

```json
{
  "event": "INGEST_PACKET",
  "callsign": "ALPHA-1",
  "timestamp": 1727467563000,
  "data": {
    "packetId": "msg-1727467563-abc123",
    "channelId": "chan-cmd-net-02",
    "sourceLanguage": "en",
    "targetLanguage": "te",
    "compactTextPayload": "All units report to rendezvous point Charlie.",
    "priority": "PRIORITY_ROUTINE",
    "latitude": 17.3850,
    "longitude": 78.4867
  }
}
```

Server Action: Persist packet, broadcast INGEST_PACKET_RECEIVED to all channel subscribers.

---

#### CRITICAL_SOS — Emergency broadcast

```json
{
  "event": "CRITICAL_SOS",
  "callsign": "ALPHA-1",
  "timestamp": 1727467563000,
  "data": {
    "packetId": "sos-1727467563-xyz789",
    "channelId": "chan-emergency-01",
    "compactTextPayload": "Building collapse. 3 persons trapped. Coordinates: 17.3850, 78.4867.",
    "priority": "PRIORITY_EMERGENCY_SOS",
    "latitude": 17.3850,
    "longitude": 78.4867
  }
}
```

Server Action: Create incident, broadcast CRITICAL_SOS_TRIGGERED to ALL channels, dispatch NDMA webhook.

---

#### HEARTBEAT — Keepalive ping with telemetry (every 30 seconds)

```json
{
  "event": "HEARTBEAT",
  "callsign": "ALPHA-1",
  "timestamp": 1727467563000,
  "data": {
    "batteryPct": 88.0,
    "rssiDbm": -64.0
  }
}
```

Expected server response: HEARTBEAT_ACK event.

---

### 4.3 Server ? Client Events

#### INGEST_PACKET_RECEIVED — New message broadcast to channel subscribers

```json
{
  "event": "INGEST_PACKET_RECEIVED",
  "callsign": "BRAVO-3",
  "timestamp": 1727467563000,
  "data": {
    "packetId": "msg-1727467563-abc123",
    "channelId": "chan-cmd-net-02",
    "compactTextPayload": "Sector 3 secured. Requesting extraction.",
    "priority": "PRIORITY_ROUTINE",
    "latitude": 17.3860,
    "longitude": 78.4900
  }
}
```

Flutter parses: data.compactTextPayload, data.packetId, data.priority, callsign

---

#### CRITICAL_SOS_TRIGGERED — Emergency alert pushed to all subscribers

```json
{
  "event": "CRITICAL_SOS_TRIGGERED",
  "callsign": "DELTA-7",
  "timestamp": 1727467563000,
  "data": {
    "incidentId": "inc-uuid-0001",
    "packetId": "sos-1727467563-xyz789",
    "alertType": "CRITICAL_SOS_BROADCAST",
    "channelId": "chan-emergency-01",
    "compactTextPayload": "Building collapse. 3 persons trapped.",
    "latitude": 17.3850,
    "longitude": 78.4867
  }
}
```

Flutter parses: data.incidentId, callsign, data.packetId, data.alertType

---

#### TRANSCEIVER_JOINED_CHANNEL — Channel subscription confirmed

```json
{
  "event": "TRANSCEIVER_JOINED_CHANNEL",
  "callsign": "SERVER",
  "timestamp": 1727467563000,
  "data": {
    "channelId": "chan-cmd-net-02",
    "callsign": "ALPHA-1",
    "activeSubscribers": 5
  }
}
```

---

#### HEARTBEAT_ACK — Keepalive acknowledgment

```json
{
  "event": "HEARTBEAT_ACK",
  "callsign": "SERVER",
  "timestamp": 1727467563000,
  "data": { "serverTime": "2026-09-27T22:36:03Z" }
}
```

---

#### INCIDENT_STATUS_UPDATE — Incident lifecycle notification

```json
{
  "event": "INCIDENT_STATUS_UPDATE",
  "callsign": "SERVER",
  "timestamp": 1727467563000,
  "data": {
    "incidentId": "inc-uuid-0001",
    "status": "FIRST_RESPONDER_ASSIGNED",
    "firstResponderAssigned": "ALPHA-1",
    "updatedAt": "2026-09-27T22:40:00Z"
  }
}
```

---

### 4.4 Heartbeat Protocol

| Party | Action | Interval |
|---|---|---|
| Flutter App | Sends HEARTBEAT frame | Every 30 seconds |
| Server | Responds with HEARTBEAT_ACK | Within 5 seconds |
| Server | Closes connection if no HEARTBEAT received | After 90 seconds |
| Flutter App | Auto-reconnects after disconnect | After 5 seconds |

---

## 5. Database Schema Requirements

### tbl_channels (Must replace in-memory state)
```sql
CREATE TABLE tbl_channels (
  channel_id        VARCHAR(64) PRIMARY KEY,
  name              VARCHAR(128) NOT NULL,
  description       TEXT,
  frequency_mhz     DECIMAL(8, 3),
  is_encrypted      BOOLEAN DEFAULT FALSE,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);
```

### tbl_transmissions (PostgreSQL + PostGIS)
```sql
CREATE TABLE tbl_transmissions (
  packet_id              VARCHAR(128) PRIMARY KEY,
  sender_callsign        VARCHAR(64) NOT NULL,
  recipient_callsign     VARCHAR(64),
  channel_id             VARCHAR(64) REFERENCES tbl_channels(channel_id),
  compact_text_payload   TEXT NOT NULL,
  priority               VARCHAR(32) DEFAULT 'PRIORITY_ROUTINE',
  transport_used         VARCHAR(32) DEFAULT 'WIFI_DIRECT',
  location               GEOMETRY(Point, 4326),
  created_at             TIMESTAMPTZ DEFAULT NOW()
);
```

### tbl_incidents
```sql
CREATE TABLE tbl_incidents (
  incident_id                VARCHAR(128) PRIMARY KEY,
  packet_id                  VARCHAR(128) REFERENCES tbl_transmissions(packet_id),
  initiating_callsign        VARCHAR(64) NOT NULL,
  alert_type                 VARCHAR(64) DEFAULT 'CRITICAL_SOS_BROADCAST',
  status                     VARCHAR(64) DEFAULT 'ACTIVE_DISPATCH',
  first_responder_assigned   VARCHAR(64),
  created_at                 TIMESTAMPTZ DEFAULT NOW(),
  resolved_at                TIMESTAMPTZ
);
```

### tbl_devices
```sql
CREATE TABLE tbl_devices (
  device_id           VARCHAR(128) PRIMARY KEY,
  callsign            VARCHAR(64) UNIQUE NOT NULL,
  device_fingerprint  VARCHAR(256),
  unit_type           VARCHAR(64) DEFAULT 'FIELD_TRANSCEIVER',
  registered_at       TIMESTAMPTZ DEFAULT NOW(),
  last_seen_at        TIMESTAMPTZ
);
```

### Redis — Active Channel Presence
```
KEY:   active:channel:<channelId>:subscribers
TYPE:  SET
VALUE: Set of currently subscribed callsigns
TTL:   90 seconds (refreshed on each HEARTBEAT received)
```

---

## 6. Prioritized Action Items

### ?? P0 — Immediate Blockers (Flutter integration broken without these)

| # | Item | Endpoint |
|---|---|---|
| P0-1 | Implement device auth & token issuance | POST /api/v1/auth/token + POST /api/v1/auth/device-register |
| P0-2 | Enforce WS auth on upgrade request | Authorization: Bearer header on WS handshake |
| P0-3 | Handle SUBSCRIBE command on WS gateway | SUBSCRIBE ? TRANSCEIVER_JOINED_CHANNEL |
| P0-4 | Broadcast INGEST_PACKET_RECEIVED to channel subscribers | On INGEST_PACKET received |
| P0-5 | Stage Whisper ONNX & Piper TTS model binaries | GET /api/v1/models/download/{id} |
| P0-6 | Make channels persistent (PostgreSQL, not in-memory) | tbl_channels, tbl_transmissions |

### ?? P1 — High Priority (Offline-first & data retrieval)

| # | Item | Endpoint |
|---|---|---|
| P1-1 | Implement offline batch sync | POST /api/v1/transmissions/sync |
| P1-2 | Implement channel message history | GET /api/v1/channels/{channelId}/messages?limit=&since= |
| P1-3 | Implement active incidents query | GET /api/v1/incidents/active |
| P1-4 | Implement HEARTBEAT_ACK response | WS: HEARTBEAT ? HEARTBEAT_ACK |
| P1-5 | Broadcast INCIDENT_STATUS_UPDATE on status change | WS broadcast |
| P1-6 | Idempotent packet ingest (skip duplicate packetId) | POST /api/v1/ingest + sync endpoint |

### ? P2 — Production Hardening

| # | Item |
|---|---|
| P2-1 | Protobuf v3 support: deliver transmission.pb.dart and enable binary WS frames |
| P2-2 | NDMA external dispatch webhook verification for SOS |
| P2-3 | Air-gapped K3s edge node Docker Compose package for Raspberry Pi 5 |
| P2-4 | Ed25519 cryptographic signature validation on SOS packets |
| P2-5 | Token refresh endpoint POST /api/v1/auth/refresh |
| P2-6 | Push/wakeup notification for inactive field devices during emergency broadcast |

---

## 7. Error Response Standard

All REST endpoints must return errors in this consistent JSON format:

```json
{
  "error": "ERROR_CODE_IN_SCREAMING_SNAKE_CASE",
  "message": "Human readable description of what went wrong.",
  "timestamp": "2026-09-27T22:36:03Z"
}
```

| HTTP Code | When to Use |
|---|---|
| 200 | Successful GET or update |
| 201 | Successful POST creating a resource |
| 400 | Invalid request body or missing required fields |
| 401 | Invalid or missing Bearer token |
| 403 | Token valid but callsign not authorized for channel |
| 404 | Channel or resource does not exist |
| 409 | Duplicate packetId on ingest |
| 500 | Unhandled server exception |

---

## Appendix A: Flutter App Config Reference

File: lib/core/config/api_config.dart

```dart
static BackendEnvironment currentEnvironment = BackendEnvironment.production;
static String callsign = 'ALPHA-1';
static String deviceId = 'dev-alpha-001-node';
static String bearerToken = '<REPLACE_WITH_BACKEND_PROVIDED_TOKEN>';
static String activeChannelId = 'chan-cmd-net-02';
```

To unblock development immediately: provide a staging Bearer token that is accepted by the backend, even as a static API key. The Flutter team will wire the dynamic auth flow once POST /api/v1/auth/token is implemented.

---

*Document generated from iTantra Flutter codebase — lib/services/api/api_service.dart, lib/services/websocket/transceiver_websocket_service.dart, lib/core/config/api_config.dart — September 2026.*
