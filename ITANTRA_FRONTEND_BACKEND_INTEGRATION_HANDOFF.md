# iTantra Backend → Flutter Frontend Integration Handoff

## Purpose

This document lists the backend capabilities already implemented and the information the Flutter/Android frontend team needs to integrate with the backend.

**Backend responsibility:** APIs, authentication, WebSocket communication, channels, SOS, telemetry, database persistence, NATS messaging, and AI model-management APIs.

**Frontend responsibility:** Flutter UI, Android device integration, microphone/audio handling, and later on-device AI integration (VAD/STT/TTS).

---

# 1. Backend Services

The backend currently consists of:

- Next.js 15 / Node.js backend
- REST API endpoints
- WebSocket stream gateway
- PostgreSQL/Prisma persistence
- NATS messaging
- Channel management
- SOS handling
- Telemetry handling
- AI model metadata/download management

The core mobile communication flow expected by the backend is:

```text
Flutter / Android App
        |
        | REST / WebSocket
        v
   iTantra Backend
        |
   +----+----------------+
   |    |       |        |
  API  WS     DB       NATS
```

---

# 2. Backend Base URLs

## Android Emulator

```dart
const String apiBaseUrl = 'http://10.0.2.2:3000';
const String wsGatewayUrl =
    'ws://10.0.2.2:8443/v1/transceiver/channel';
```

## Physical Android Device

Use the backend machine's LAN IP:

```text
http://<SERVER-LAN-IP>:3000
ws://<SERVER-LAN-IP>:8443/v1/transceiver/channel
```

The phone and development computer must be on the same network.

---

# 3. Authentication

Mutating backend endpoints require the device callsign.

Required header:

```http
x-transceiver-callsign: BRAVO-4
```

For production, Bearer authentication is also required:

```http
Authorization: Bearer <DEV_OR_PRODUCTION_TOKEN>
```

Do **not** hardcode authentication tokens inside the Flutter application.

For local development, the backend may accept the callsign without a Bearer token according to the current development configuration.

---

# 4. Health Check

## GET

```text
/api/healthz
```

Full example:

```text
http://10.0.2.2:3000/api/healthz
```

Used by the frontend to verify that the backend is reachable.

Expected response contains:

```json
{
  "status": "HEALTHY",
  "uptime": 123,
  "timestamp": "...",
  "services": {
    "c2Portal": "...",
    "streamGateway": "...",
    "database": "..."
  }
}
```

---

# 5. Normal Message / Packet Ingest

## POST

```text
/api/v1/ingest
```

Headers:

```http
Content-Type: application/json
x-transceiver-callsign: BRAVO-4
```

Request:

```json
{
  "senderCallsign": "BRAVO-4",
  "compactTextPayload": "PATROL CHECKPOINT CHARLIE SECURE",
  "transportUsed": "WIFI_DIRECT",
  "priority": "PRIORITY_ROUTINE",
  "latitude": 17.3616,
  "longitude": 78.4747
}
```

Expected response:

```json
{
  "success": true,
  "packetId": "...",
  "status": "DELIVERED"
}
```

### Flutter use

When the mobile side has text ready to transmit, call this endpoint.

The text can later come from the on-device STT system.

---

# 6. Emergency SOS

## POST

```text
/api/v1/sos
```

Headers:

```http
Content-Type: application/json
x-transceiver-callsign: RAVEN-2
```

Request:

```json
{
  "senderCallsign": "RAVEN-2",
  "compactTextPayload": "EXTRACTION POINT COMPROMISED - FALLBACK ALPHA",
  "transportUsed": "TACTICAL_GATEWAY",
  "latitude": 17.3912,
  "longitude": 78.4920
}
```

Expected response:

```json
{
  "success": true,
  "incidentId": "...",
  "packetId": "...",
  "status": "ACTIVE_DISPATCH"
}
```

### Flutter use

The SOS button in the application should trigger this API.

The backend also broadcasts the SOS event through WebSocket.

---

# 7. Telemetry

## POST

```text
/api/v1/telemetry
```

Headers:

```http
Content-Type: application/json
x-transceiver-callsign: BRAVO-4
```

Request:

```json
{
  "callsign": "BRAVO-4",
  "batteryPercent": 84,
  "signalStrengthDbm": -62,
  "transportType": "WIFI_DIRECT",
  "latitude": 17.3616,
  "longitude": 78.4747,
  "nodeTemperatureC": 38.2
}
```

Expected response:

```json
{
  "success": true,
  "reportId": "...",
  "status": "RECORDED"
}
```

### Flutter use

The Android app can periodically send:

- Battery percentage
- Signal strength
- Transport type
- Location
- Device temperature

---

# 8. Channels

## Get channels

### GET

```text
/api/v1/channels
```

The backend currently provides three static channels:

```text
EMERGENCY_BROADCAST
COMMAND_NET
SECTOR_4_TAC
```

The returned objects contain channel information such as:

- channel ID
- channel name
- frequency
- encryption status
- subscriber information

## Join / assign channel

### POST

```text
/api/v1/channels
```

Request:

```json
{
  "callsign": "BRAVO-4",
  "channelId": "chan-cmd-net-02"
}
```

The backend returns the channel assignment and emits a channel-join event.

### Current limitation

Channel state is currently **in-memory**. It is not yet a persistent channel-management system.

---

# 9. WebSocket

## Gateway

```text
ws://<SERVER>:8443/v1/transceiver/channel
```

Android Emulator:

```text
ws://10.0.2.2:8443/v1/transceiver/channel
```

Optional handshake header:

```http
x-transceiver-callsign: BRAVO-4
```

The frontend should maintain a WebSocket connection for real-time events.

---

# 10. WebSocket Events

The backend currently provides these important events.

## CRITICAL_SOS_TRIGGERED

Generated when an emergency SOS is received.

Frontend should:

- Display emergency alert
- Give it highest UI priority
- Update the emergency screen/status
- Later integrate the required high-volume/non-interruptible audio behavior

## INGEST_PACKET_RECEIVED

Generated when a normal communication packet is received.

Frontend should:

- Display the received message
- Associate it with the sender
- Update the communication screen

## TRANSCEIVER_JOINED_CHANNEL

Generated when a transceiver joins a channel.

Frontend can:

- Update channel/member information
- Show the active channel state

The exact event payload should be handled according to the backend response/event schema.

---

# 11. AI Model Management APIs

The backend exposes model-management endpoints for the mobile application.

## Get model manifest

### GET

```text
/api/v1/models
```

The current manifest contains model metadata for:

```text
whisper-base-tactical-onnx
piper-tactical-voice-onnx
intent-classifier-gguf
```

Metadata includes information such as:

- model ID
- model type
- format
- size
- SHA-256
- edge-optimization flag

### Important

These APIs provide **model management/metadata**.

They do NOT mean that actual VAD, Whisper STT or Piper TTS inference is being performed by the backend.

The actual on-device AI inference belongs to the Android/Flutter side.

---

# 12. Model Download

## GET

```text
/api/v1/models/download/:id
```

The backend supports conditional model delivery:

- If S3/object storage is configured → redirect to the stored artifact.
- If a local model artifact exists → stream the file.
- If no artifact is available → return a storage/model-not-configured response.

### Current prototype limitation

The actual model binaries are not yet staged/configured in the backend environment.

Therefore, the frontend should not assume that every model download will currently succeed.

---

# 13. What the Flutter Frontend Can Build Now

The frontend team can integrate:

### Communication

- Device/callsign setup
- Backend connection
- Send text packets
- Receive text packets
- WebSocket real-time events
- Channel list
- Channel joining

### Emergency

- SOS button
- SOS API integration
- Real-time SOS event handling
- Emergency UI

### Device information

- Telemetry collection
- Battery status
- Signal information
- Location information
- Device status

### Backend connectivity

- Health check
- Connection status
- API error handling
- WebSocket reconnect logic

---

# 14. Backend → Frontend Responsibility Boundary

## Backend team — completed

```text
REST APIs
Authentication
WebSocket Gateway
Normal Packet Ingest
SOS
Telemetry
Channels
Database Persistence
NATS Messaging
Model Manifest
Model Download Endpoint
Health Check
```

## Flutter / Android team

```text
Flutter UI
Android permissions
Microphone integration
Speaker/audio playback
PTT UI
Device-side networking integration
WebSocket client
REST API client
Local application state
Offline UI behavior
```

## AI — handled separately later

```text
VAD
Offline Whisper STT
Offline Piper TTS
On-device model loading
Language model integration
AI performance optimization
```

---

# 15. Current Backend Limitations

These are important so the frontend team does not assume unsupported functionality:

| Feature | Status |
|---|---|
| REST APIs | IMPLEMENTED |
| Authentication | IMPLEMENTED |
| WebSocket gateway | IMPLEMENTED |
| SOS | IMPLEMENTED |
| Normal ingest | IMPLEMENTED |
| Telemetry | IMPLEMENTED |
| Channels | IN-MEMORY |
| Model manifest | STATIC METADATA |
| Model binary artifacts | NOT YET STAGED/CONFIGURED |
| Opus/raw PCM audio streaming | NOT IMPLEMENTED |
| FCM/APNs push notifications | NOT IMPLEMENTED |
| VAD/Whisper/Piper inference in backend | NOT IMPLEMENTED |

---

# 16. Recommended Frontend Integration Order

### Step 1 — Backend connectivity

Test:

```text
GET /api/healthz
```

### Step 2 — Device identity

Configure:

```text
callsign
```

and required authentication headers.

### Step 3 — Normal communication

Implement:

```text
POST /api/v1/ingest
```

### Step 4 — WebSocket

Connect to:

```text
/v1/transceiver/channel
```

and handle:

```text
INGEST_PACKET_RECEIVED
CRITICAL_SOS_TRIGGERED
TRANSCEIVER_JOINED_CHANNEL
```

### Step 5 — Channels

Implement:

```text
GET /api/v1/channels
POST /api/v1/channels
```

### Step 6 — SOS

Connect the emergency button to:

```text
POST /api/v1/sos
```

### Step 7 — Telemetry

Implement periodic:

```text
POST /api/v1/telemetry
```

### Step 8 — AI integration

Do this separately after the basic frontend/backend communication is working.

---

# 17. Important Network Note

For Android Emulator:

```text
10.0.2.2
```

refers to the host computer.

For a physical Android phone:

```text
10.0.2.2
```

is generally NOT the correct address.

Use the development computer's LAN IP:

```text
http://<SERVER-LAN-IP>:3000
ws://<SERVER-LAN-IP>:8443/v1/transceiver/channel
```

Make sure:

- Phone and computer are on the same network.
- Backend ports 3000 and 8443 are reachable.
- Windows Firewall is not blocking the ports.

---

# 18. Final Handoff Summary

The backend-side integration layer required by the Flutter application is ready for frontend integration.

The Flutter developer can start with:

```text
Health
  ↓
Authentication
  ↓
Channels
  ↓
REST Ingest
  ↓
WebSocket
  ↓
SOS
  ↓
Telemetry
```

AI can be integrated later.

**The backend should be treated as a text/event communication backend, not as the location where Whisper/Piper/VAD inference runs.**
