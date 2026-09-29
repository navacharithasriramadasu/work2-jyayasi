# iTantra SIH 2026 — Frontend ↔ Backend Integration Handoff

**Project:** iTantra – Indian Multilingual TTS & STT Aided Neural Transceiver Radio Access for Low-Bitrate Links  
**Purpose:** Comprehensive Frontend & Mobile Developer API & Integration Reference  
**Source Specifications:** `complete_backend_requirements.md`, `BACKEND_REQUIREMENTS_AND_DEPLOYMENT.md`, `ITANTRA_FRONTEND_BACKEND_INTEGRATION_HANDOFF.md`

---

## 1. System Boundary

### Frontend / Mobile (Android / Flutter)
- Microphone capture and hardware/software Push-to-Talk (PTT)
- Local Voice Activity Detection (VAD), Speech-to-Text (STT via Vosk / Whisper Int8 ONNX), and Text-to-Speech (TTS via Piper Indic ONNX)
- Local offline message SQLite/Hive storage and automatic retry queue
- Offline Peer-to-Peer mesh communication (Wi-Fi Direct / BLE)
- REST and WebSocket communication with the backend C2 gateway
- Cryptographic identity, device registration, and JWT token management
- Tactical channel switching, message history, SOS dispatch, and active incident UI
- AI model manifest retrieval, resumable OTA download, and SHA-256 verification

### Backend (Next.js C2 Portal & Node.js Stream Gateway)
- Device registration, challenge-response verification, and JWT issuance / refresh
- Compact text packet ingestion (`POST /api/v1/ingest`)
- High-throughput WebSocket stream relay (`wss://.../v1/transceiver/channel`)
- Persistent channel registry and channel-specific message history with pagination
- Offline backlog batch synchronization (`POST /api/v1/transmissions/sync`)
- Emergency SOS triage, incident dispatch, and responder state management
- Real-time device telemetry ingestion (battery, RSSI, drop rate, location)
- AI neural model manifest and HTTP/2 range-resumable OTA binary downloads
- Upstream dispatch integration (NDMA webhook relay) and health monitoring

> [!IMPORTANT]
> **Normal voice communication transmits compact text (<80 bytes) rather than raw audio streams.**  
> Neural inference (VAD, STT, and TTS) runs locally on the mobile transceiver handset. The backend acts as a C2 portal, real-time message relay, and cloud/edge synchronization bridge.

---

## 2. Environment Base URLs & Configuration

The backend supports multiple operational deployment topologies:

| Environment | Base REST API URL | WebSocket Stream Gateway URL | Description |
|---|---|---|---|
| **Production Cloud (Render)** | `https://itantra-c2-portal.onrender.com` | `wss://itantra-stream-gateway.onrender.com/v1/transceiver/channel` | Active live cloud deployment |
| **Android Emulator** | `http://10.0.2.2:3000` | `ws://10.0.2.2:8443/v1/transceiver/channel` | Local dev with host machine loopback |
| **Physical Device on LAN** | `http://<HOST_IP>:3000` | `ws://<HOST_IP>:8443/v1/transceiver/channel` | Wi-Fi testnet on workstation LAN |
| **Field Edge Node (K3s)** | `http://192.168.10.1:3000` | `ws://192.168.10.1:8443/v1/transceiver/channel` | Rugged air-gapped field edge box |
| **Custom Production Domain** | `https://c2.itantra.org` | `wss://stream.itantra.org/v1/transceiver/channel` | Enterprise Cloudflare WAF deployment |

### Flutter Environment Configuration

```dart
enum BackendEnvironment { production, emulator, lan, fieldEdge, customDomain }

class ApiConfig {
  static BackendEnvironment currentEnvironment = BackendEnvironment.production;

  // Change custom LAN IP when testing on physical devices
  static const String lanHostIp = '192.168.1.100';

  static String get baseUrl {
    switch (currentEnvironment) {
      case BackendEnvironment.production:
        return 'https://itantra-c2-portal.onrender.com';
      case BackendEnvironment.emulator:
        return 'http://10.0.2.2:3000';
      case BackendEnvironment.lan:
        return 'http://$lanHostIp:3000';
      case BackendEnvironment.fieldEdge:
        return 'http://192.168.10.1:3000';
      case BackendEnvironment.customDomain:
        return 'https://c2.itantra.org';
    }
  }

  static String get wsUrl {
    switch (currentEnvironment) {
      case BackendEnvironment.production:
        return 'wss://itantra-stream-gateway.onrender.com/v1/transceiver/channel';
      case BackendEnvironment.emulator:
        return 'ws://10.0.2.2:8443/v1/transceiver/channel';
      case BackendEnvironment.lan:
        return 'ws://$lanHostIp:8443/v1/transceiver/channel';
      case BackendEnvironment.fieldEdge:
        return 'ws://192.168.10.1:8443/v1/transceiver/channel';
      case BackendEnvironment.customDomain:
        return 'wss://stream.itantra.org/v1/transceiver/channel';
    }
  }
}
```

> [!WARNING]
> Never hardcode production JWT tokens, private cryptographic keys, or credentials directly in frontend source code.

---

## 3. Authentication & Security

All authenticated requests must include the following headers:

```http
Authorization: Bearer <JWT_TOKEN>
x-transceiver-callsign: <CALLSIGN>
Content-Type: application/json
```

### 3.1 Register Device

Registers the hardware device, associates its cryptographic public key, and returns an authentication challenge.

- **Method:** `POST`
- **Relative Path:** `/api/v1/auth/register`
- **Full Production URL:** `https://itantra-c2-portal.onrender.com/api/v1/auth/register`
- **Full Emulator URL:** `http://10.0.2.2:3000/api/v1/auth/register`
- **Auth Required:** No

#### Request Headers
```http
Content-Type: application/json
```

#### Request Body
```json
{
  "deviceId": "dev-alpha-001-node",
  "callsign": "ALPHA-1",
  "operatorName": "Major Vikram",
  "hardwareModel": "Handheld-RT-01",
  "publicKeyPem": "-----BEGIN PUBLIC KEY-----\nMCowBQYDK2VwAyEA9...\n-----END PUBLIC KEY-----",
  "primaryTransport": "TACTICAL_UPLINK",
  "firmwareVersion": "1.4.0",
  "aiModelVersion": "2.1.0"
}
```

#### Response Body (`201 Created` / `200 OK`)
```json
{
  "status": "REGISTERED",
  "deviceId": "dev-alpha-001-node",
  "callsign": "ALPHA-1",
  "challenge": "e7b99c0d-13a8-44fb-8fa4-1065c7198ba2"
}
```

---

### 3.2 Obtain Token

Exchanges the device hardware identity and signed challenge (or timestamp proof) for an authenticated Bearer JWT.

- **Method:** `POST`
- **Relative Path:** `/api/v1/auth/token`
- **Full Production URL:** `https://itantra-c2-portal.onrender.com/api/v1/auth/token`
- **Full Emulator URL:** `http://10.0.2.2:3000/api/v1/auth/token`
- **Auth Required:** No

#### Request Headers
```http
Content-Type: application/json
```

#### Request Body
```json
{
  "deviceId": "dev-alpha-001-node",
  "callsign": "ALPHA-1",
  "signedChallenge": "c3VwZXJzZWNyZXRzaWduYXR1cmVkYXRh...",
  "timestamp": 1727375000000
}
```

#### Response Body (`200 OK`)
```json
{
  "tokenType": "Bearer",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "ref_8390af2b947c458d928014...",
  "expiresInSeconds": 86400,
  "assignedChannels": [
    "chan-cmd-net-01",
    "chan-tac-alpha-02"
  ]
}
```

---

### 3.3 Refresh Token

Renews an expiring Bearer JWT without re-prompting or re-registering the hardware device.

- **Method:** `POST`
- **Relative Path:** `/api/v1/auth/refresh`
- **Full Production URL:** `https://itantra-c2-portal.onrender.com/api/v1/auth/refresh`
- **Full Emulator URL:** `http://10.0.2.2:3000/api/v1/auth/refresh`
- **Auth Required:** No (uses refresh token) or Bearer header

#### Request Headers
```http
Content-Type: application/json
```

#### Request Body
```json
{
  "callsign": "ALPHA-1",
  "refreshToken": "ref_8390af2b947c458d928014..."
}
```

#### Response Body (`200 OK`)
```json
{
  "tokenType": "Bearer",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.new...",
  "refreshToken": "ref_new_93810ef...",
  "expiresInSeconds": 86400
}
```

---

## 4. REST API Master Quick Reference

| # | Method | Relative Endpoint | Full Production URL | Purpose | Auth |
|:---:|:---:|---|---|---|:---:|
| 1 | `POST` | `/api/v1/auth/register` | `https://itantra-c2-portal.onrender.com/api/v1/auth/register` | Device registration & challenge | None |
| 2 | `POST` | `/api/v1/auth/token` | `https://itantra-c2-portal.onrender.com/api/v1/auth/token` | JWT Token issuance | None |
| 3 | `POST` | `/api/v1/auth/refresh` | `https://itantra-c2-portal.onrender.com/api/v1/auth/refresh` | JWT Token renewal | None / Ref |
| 4 | `POST` | `/api/v1/ingest` | `https://itantra-c2-portal.onrender.com/api/v1/ingest` | Single compact-text transmission | Bearer |
| 5 | `POST` | `/api/v1/transmissions/sync` | `https://itantra-c2-portal.onrender.com/api/v1/transmissions/sync` | Offline backlog batch sync | Bearer |
| 6 | `POST` | `/api/v1/sos` | `https://itantra-c2-portal.onrender.com/api/v1/sos` | Priority emergency SOS trigger | Bearer |
| 7 | `GET` | `/api/v1/incidents/active` | `https://itantra-c2-portal.onrender.com/api/v1/incidents/active` | Active SOS incidents list | Bearer |
| 8 | `PATCH` | `/api/v1/incidents/{incidentId}` | `https://itantra-c2-portal.onrender.com/api/v1/incidents/{incidentId}` | Incident assignment / resolution | Bearer |
| 9 | `GET` | `/api/v1/channels` | `https://itantra-c2-portal.onrender.com/api/v1/channels` | List tactical channels | Bearer |
| 10 | `POST` | `/api/v1/channels` | `https://itantra-c2-portal.onrender.com/api/v1/channels` | Join / assign active channel | Bearer |
| 11 | `GET` | `/api/v1/channels/{channelId}/messages` | `https://itantra-c2-portal.onrender.com/api/v1/channels/{channelId}/messages` | Paginated channel history | Bearer |
| 12 | `POST` | `/api/v1/telemetry` | `https://itantra-c2-portal.onrender.com/api/v1/telemetry` | Ingest node battery & health | Bearer |
| 13 | `GET` | `/api/v1/models/manifest` | `https://itantra-c2-portal.onrender.com/api/v1/models/manifest` | AI model catalog (alias `/models`) | Bearer |
| 14 | `GET` | `/api/v1/models/download/{modelId}` | `https://itantra-c2-portal.onrender.com/api/v1/models/download/{modelId}` | Resumable model binary download | Bearer |
| 15 | `GET` | `/api/healthz` | `https://itantra-c2-portal.onrender.com/api/healthz` | System health status | None |

---

## 5. Normal Transmission (Single Packet Ingestion)

Ingests compact text recognized by on-device STT into the C2 system and fans it out across tactical networks.

- **Method:** `POST`
- **Relative Path:** `/api/v1/ingest`
- **Full Production URL:** `https://itantra-c2-portal.onrender.com/api/v1/ingest`
- **Full Emulator URL:** `http://10.0.2.2:3000/api/v1/ingest`
- **Auth Required:** Yes

#### Request Headers
```http
Authorization: Bearer <JWT_TOKEN>
x-transceiver-callsign: ALPHA-1
Content-Type: application/json
```

#### Request Body
```json
{
  "packetId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "senderCallsign": "ALPHA-1",
  "recipientCallsign": "BROADCAST_ALL",
  "channelId": "chan-cmd-net-01",
  "sourceLanguage": "te",
  "targetLanguage": "te",
  "compactTextPayload": "అత్యవసర విభాగం సిద్ధంగా ఉంది",
  "priority": "PRIORITY_ROUTINE",
  "transportUsed": "WIFI_DIRECT",
  "location": {
    "latitude": 17.3850,
    "longitude": 78.4867,
    "altitudeMeters": 505
  },
  "timestamp": 1727375050000,
  "signature": "sig_ed25519_mock_or_device_hash"
}
```

#### Response Body (`200 OK` / `201 Created`)
```json
{
  "packetId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "status": "PROCESSED",
  "serverTimestamp": 1727375050012
}
```

#### Priority Enum Values
- `PRIORITY_ROUTINE`: Standard voice chatter and status reports
- `PRIORITY_HIGH`: Urgent operational orders and priority tactical updates
- `PRIORITY_EMERGENCY_SOS`: Life-safety red alerts

#### Transport Enum Values
- `WIFI_DIRECT`: High-speed peer-to-peer Wi-Fi cluster
- `BLUETOOTH_LE`: Low-energy tactical mesh radio
- `TACTICAL_GATEWAY`: Relay through a stationary field edge node
- `SATELLITE`: Direct or relayed satcom uplink
- `TACTICAL_UPLINK`: LTE/5G or Ethernet C2 backhaul

---

## 6. Offline Synchronization (Backlog Batch Ingest)

When an air-gapped unit operating offline regains connectivity, it flushes queued transmissions to the backend in a single atomic/idempotent call.

- **Method:** `POST`
- **Relative Path:** `/api/v1/transmissions/sync`
- **Full Production URL:** `https://itantra-c2-portal.onrender.com/api/v1/transmissions/sync`
- **Full Emulator URL:** `http://10.0.2.2:3000/api/v1/transmissions/sync`
- **Auth Required:** Yes

#### Request Headers
```http
Authorization: Bearer <JWT_TOKEN>
x-transceiver-callsign: ALPHA-1
Content-Type: application/json
```

#### Request Body
```json
{
  "deviceId": "dev-alpha-001-node",
  "packets": [
    {
      "packetId": "1b9d6bcd-bbfd-4b2d-9b5d-ab8dfbbd4bed",
      "senderCallsign": "ALPHA-1",
      "recipientCallsign": "BRAVO-2",
      "channelId": "chan-tac-alpha-02",
      "sourceLanguage": "hi",
      "targetLanguage": "hi",
      "compactTextPayload": "सेक्टर 4 में स्थिति सामान्य है",
      "priority": "PRIORITY_HIGH",
      "transportUsed": "BLUETOOTH_LE",
      "latitude": 17.3852,
      "longitude": 78.4860,
      "timestamp": 1727371000000
    },
    {
      "packetId": "2c9d6bcd-bbfd-4b2d-9b5d-ab8dfbbd4bee",
      "senderCallsign": "ALPHA-1",
      "recipientCallsign": "BROADCAST_ALL",
      "channelId": "chan-tac-alpha-02",
      "sourceLanguage": "te",
      "targetLanguage": "te",
      "compactTextPayload": "మరింత బలం అవసరం లేదు",
      "priority": "PRIORITY_ROUTINE",
      "transportUsed": "WIFI_DIRECT",
      "latitude": 17.3855,
      "longitude": 78.4862,
      "timestamp": 1727371200000
    }
  ]
}
```

#### Response Body (`200 OK`)
```json
{
  "success": true,
  "syncedCount": 2,
  "failedPackets": [],
  "serverEpochMs": 1727375100000
}
```

---

## 7. Emergency SOS

Triggers an immediate high-priority emergency broadcast across C2 monitors, relays via NATS, and generates an active incident record.

- **Method:** `POST`
- **Relative Path:** `/api/v1/sos`
- **Full Production URL:** `https://itantra-c2-portal.onrender.com/api/v1/sos`
- **Full Emulator URL:** `http://10.0.2.2:3000/api/v1/sos`
- **Auth Required:** Yes

#### Request Headers
```http
Authorization: Bearer <JWT_TOKEN>
x-transceiver-callsign: ALPHA-1
Content-Type: application/json
```

#### Request Body
```json
{
  "senderCallsign": "ALPHA-1",
  "recipientCallsign": "BROADCAST_ALL",
  "compactTextPayload": "MAYDAY MAYDAY COLLAPSED STRUCTURE AT SECTOR 4 NEED IMMEDIATE MEDEVAC",
  "priority": "PRIORITY_EMERGENCY_SOS",
  "transportUsed": "WIFI_DIRECT",
  "latitude": 17.3850,
  "longitude": 78.4867
}
```

#### Response Body (`201 Created` / `200 OK`)
```json
{
  "success": true,
  "incidentId": "inc-9821a-45c1-90ef-827361928374",
  "packetId": "pkt-sos-7712-9901",
  "status": "ACTIVE_DISPATCH"
}
```

---

## 8. Active Incidents Query

Retrieves all currently active emergency incidents so the mobile UI HUD and map display pending SOS alerts.

- **Method:** `GET`
- **Relative Path:** `/api/v1/incidents/active`
- **Full Production URL:** `https://itantra-c2-portal.onrender.com/api/v1/incidents/active`
- **Full Emulator URL:** `http://10.0.2.2:3000/api/v1/incidents/active`
- **Auth Required:** Yes

#### Request Headers
```http
Authorization: Bearer <JWT_TOKEN>
x-transceiver-callsign: ALPHA-1
```

#### Response Body (`200 OK`)
```json
{
  "success": true,
  "totalActive": 1,
  "incidents": [
    {
      "incidentId": "inc-9821a-45c1-90ef-827361928374",
      "packetId": "pkt-sos-7712-9901",
      "initiatingCallsign": "ALPHA-1",
      "alertType": "CRITICAL_SOS_BROADCAST",
      "status": "ACTIVE_DISPATCH",
      "firstResponderAssigned": null,
      "createdAt": "2026-09-27T16:44:10.000Z",
      "resolvedAt": null
    }
  ]
}
```

---

## 9. Incident Assignment

Assigns a first responder unit to an active emergency incident.

- **Method:** `PATCH`
- **Relative Path:** `/api/v1/incidents/{incidentId}`
- **Full Production URL:** `https://itantra-c2-portal.onrender.com/api/v1/incidents/{incidentId}`
- **Full Emulator URL:** `http://10.0.2.2:3000/api/v1/incidents/{incidentId}`
- **Auth Required:** Yes

#### Request Headers
```http
Authorization: Bearer <JWT_TOKEN>
x-transceiver-callsign: COMMAND-C2
Content-Type: application/json
```

#### Request Body
```json
{
  "action": "ASSIGN",
  "responder": "RESCUE_TEAM_BRAVO"
}
```

#### Response Body (`200 OK`)
```json
{
  "success": true,
  "action": "ASSIGN",
  "incident": {
    "incidentId": "inc-9821a-45c1-90ef-827361928374",
    "status": "RESPONDER_ASSIGNED",
    "firstResponderAssigned": "RESCUE_TEAM_BRAVO"
  }
}
```

---

## 10. Incident Resolution

Marks an incident as officially resolved once first responders clear the site.

- **Method:** `PATCH`
- **Relative Path:** `/api/v1/incidents/{incidentId}`
- **Full Production URL:** `https://itantra-c2-portal.onrender.com/api/v1/incidents/{incidentId}`
- **Full Emulator URL:** `http://10.0.2.2:3000/api/v1/incidents/{incidentId}`
- **Auth Required:** Yes

#### Request Headers
```http
Authorization: Bearer <JWT_TOKEN>
x-transceiver-callsign: COMMAND-C2
Content-Type: application/json
```

#### Request Body
```json
{
  "action": "RESOLVE"
}
```

#### Response Body (`200 OK`)
```json
{
  "success": true,
  "action": "RESOLVE",
  "incident": {
    "incidentId": "inc-9821a-45c1-90ef-827361928374",
    "status": "RESOLVED",
    "firstResponderAssigned": "RESCUE_TEAM_BRAVO",
    "resolvedAt": "2026-09-27T17:15:00.000Z"
  }
}
```

---

## 11. Channels

### 11.1 List Tactical Channels

Retrieves available radio/tactical channels, operating frequencies, and membership metrics.

- **Method:** `GET`
- **Relative Path:** `/api/v1/channels`
- **Full Production URL:** `https://itantra-c2-portal.onrender.com/api/v1/channels`
- **Full Emulator URL:** `http://10.0.2.2:3000/api/v1/channels`
- **Auth Required:** Yes

#### Response Body (`200 OK`)
```json
{
  "channels": [
    {
      "channelId": "chan-emergency-00",
      "channelName": "EMERGENCY_BROADCAST",
      "frequencyMhz": 433.92,
      "activeMembers": 24
    },
    {
      "channelId": "chan-cmd-net-01",
      "channelName": "COMMAND_NET",
      "frequencyMhz": 434.15,
      "activeMembers": 12
    },
    {
      "channelId": "chan-tac-alpha-02",
      "channelName": "SECTOR_4_TAC",
      "frequencyMhz": 434.75,
      "activeMembers": 8
    }
  ]
}
```

---

### 11.2 Join / Assign Channel

Assigns or switches the device's active listening/transmitting channel via REST.

- **Method:** `POST`
- **Relative Path:** `/api/v1/channels`
- **Full Production URL:** `https://itantra-c2-portal.onrender.com/api/v1/channels`
- **Full Emulator URL:** `http://10.0.2.2:3000/api/v1/channels`
- **Auth Required:** Yes

#### Request Headers
```http
Authorization: Bearer <JWT_TOKEN>
x-transceiver-callsign: ALPHA-1
Content-Type: application/json
```

#### Request Body
```json
{
  "callsign": "ALPHA-1",
  "channelId": "chan-cmd-net-01"
}
```

#### Response Body (`200 OK`)
```json
{
  "success": true,
  "callsign": "ALPHA-1",
  "channelId": "chan-cmd-net-01",
  "status": "JOINED",
  "channelName": "COMMAND_NET"
}
```

---

### 11.3 Channel Message History

Fetches paginated historical messages for a channel so returning or reconnecting devices catch up.

- **Method:** `GET`
- **Relative Path:** `/api/v1/channels/{channelId}/messages`
- **Full Production URL:** `https://itantra-c2-portal.onrender.com/api/v1/channels/{channelId}/messages`
- **Full Emulator URL:** `http://10.0.2.2:3000/api/v1/channels/{channelId}/messages`
- **Auth Required:** Yes

#### Query Parameters
- `since`: Epoch millisecond timestamp to fetch messages after (e.g. `?since=1727370000000`)
- `limit`: Number of records to return (Default: `50`, Max: `200`)

Example Request:
`GET https://itantra-c2-portal.onrender.com/api/v1/channels/chan-cmd-net-01/messages?since=1727370000000&limit=50`

#### Response Body (`200 OK`)
```json
{
  "channelId": "chan-cmd-net-01",
  "hasMore": false,
  "messages": [
    {
      "packetId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
      "senderCallsign": "ALPHA-1",
      "compactTextPayload": "అత్యవసర విభాగం సిద్ధంగా ఉంది",
      "priority": "PRIORITY_ROUTINE",
      "timestamp": 1727375050000
    }
  ]
}
```

---

## 12. Device Telemetry & Health Reporting

Transmits periodic device diagnostics (battery percentage, link RSSI, temperature, and drop rates) to monitor field unit readiness.

- **Method:** `POST`
- **Relative Path:** `/api/v1/telemetry`
- **Full Production URL:** `https://itantra-c2-portal.onrender.com/api/v1/telemetry`
- **Full Emulator URL:** `http://10.0.2.2:3000/api/v1/telemetry`
- **Auth Required:** Yes

#### Request Headers
```http
Authorization: Bearer <JWT_TOKEN>
x-transceiver-callsign: ALPHA-1
Content-Type: application/json
```

#### Request Body
```json
{
  "callsign": "ALPHA-1",
  "batteryPercent": 87.5,
  "signalStrengthDbm": -68.0,
  "transportType": "WIFI_DIRECT",
  "latitude": 17.3850,
  "longitude": 78.4867,
  "nodeTemperatureC": 36.4,
  "packetDropPct": 0.8
}
```

#### Response Body (`200 OK` / `201 Created`)
```json
{
  "success": true,
  "reportId": "tel-rpt-92018374",
  "status": "RECORDED"
}
```

---

## 13. Real-Time Stream Gateway (WebSocket)

The stream gateway provides bi-directional, real-time message fanout, channel subscriptions, and ping/pong heartbeats.

### Gateway Connection URLs
- **Production Cloud:** `wss://itantra-stream-gateway.onrender.com/v1/transceiver/channel`
- **Android Emulator:** `ws://10.0.2.2:8443/v1/transceiver/channel`
- **Physical Device LAN:** `ws://<HOST_IP>:8443/v1/transceiver/channel`
- **Field Edge Node:** `ws://192.168.10.1:8443/v1/transceiver/channel`
- **Custom Domain:** `wss://stream.itantra.org/v1/transceiver/channel`

### Handshake Headers
```http
x-transceiver-callsign: ALPHA-1
Authorization: Bearer <JWT_TOKEN>
```

### Frame Envelope Specification
All frames exchanged across the WebSocket gateway share a standard JSON envelope:

```json
{
  "event": "<EVENT_NAME>",
  "callsign": "<CALLSIGN>",
  "timestamp": 1727375200000,
  "data": {}
}
```

---

### 13.1 Client-to-Server Outgoing Frames

#### 1. HEARTBEAT (Keepalive Ping)
Sent every 30 seconds to maintain mobile cellular/NAT gateway sockets.

```json
{
  "event": "HEARTBEAT",
  "callsign": "ALPHA-1",
  "timestamp": 1727375200000,
  "data": {
    "batteryPct": 87.5,
    "rssiDbm": -68.0
  }
}
```

#### 2. SUBSCRIBE (Join Channel)
Subscribes the socket to incoming transmissions on a tactical channel.

```json
{
  "event": "SUBSCRIBE",
  "callsign": "ALPHA-1",
  "timestamp": 1727375201000,
  "data": {
    "channelId": "chan-cmd-net-01"
  }
}
```

#### 3. UNSUBSCRIBE (Leave Channel)
```json
{
  "event": "UNSUBSCRIBE",
  "callsign": "ALPHA-1",
  "timestamp": 1727375201000,
  "data": {
    "channelId": "chan-cmd-net-01"
  }
}
```

#### 4. INGEST_PACKET (Send Transmission)
Sends a compact-text packet over the low-latency WebSocket gateway.

```json
{
  "event": "INGEST_PACKET",
  "callsign": "ALPHA-1",
  "timestamp": 1727375205000,
  "data": {
    "packetId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    "channelId": "chan-cmd-net-01",
    "sourceLanguage": "te",
    "targetLanguage": "te",
    "compactTextPayload": "అత్యవసర విభాగం సిద్ధంగా ఉంది",
    "priority": "PRIORITY_ROUTINE",
    "latitude": 17.3850,
    "longitude": 78.4867
  }
}
```

#### 5. CRITICAL_SOS (Emergency Alert)
```json
{
  "event": "CRITICAL_SOS",
  "callsign": "ALPHA-1",
  "timestamp": 1727375205000,
  "data": {
    "packetId": "pkt-sos-7712-9901",
    "channelId": "chan-emergency-00",
    "priority": "PRIORITY_EMERGENCY_SOS"
  }
}
```

#### 6. ACK (Delivery Acknowledgment)
```json
{
  "event": "ACK",
  "callsign": "ALPHA-1",
  "timestamp": 1727375206000,
  "data": {
    "packetId": "f47ac10b-58cc-4372-a567-0e02b2c3d479"
  }
}
```

---

### 13.2 Server-to-Client Incoming Push Events

The server pushes the following frames down to connected mobile devices:

#### 1. INGEST_PACKET_RECEIVED (Incoming Transmission)
Triggered when another unit broadcasts on a channel the device is subscribed to.

```json
{
  "event": "INGEST_PACKET_RECEIVED",
  "callsign": "BRAVO-2",
  "timestamp": 1727375206500,
  "data": {
    "packetId": "1b9d6bcd-bbfd-4b2d-9b5d-ab8dfbbd4bed",
    "channelId": "chan-cmd-net-01",
    "sourceLanguage": "hi",
    "targetLanguage": "hi",
    "compactTextPayload": "सभी टीमें तैयार रहें",
    "priority": "PRIORITY_ROUTINE",
    "latitude": 17.3852,
    "longitude": 78.4860
  }
}
```

#### 2. CRITICAL_SOS_TRIGGERED (Emergency Alarm)
Triggered when ANY unit activates an SOS alert. The mobile app must trigger full-volume non-interruptible audio alerts.

```json
{
  "event": "CRITICAL_SOS_TRIGGERED",
  "callsign": "ALPHA-1",
  "timestamp": 1727375205500,
  "data": {
    "incidentId": "inc-9821a-45c1-90ef-827361928374",
    "packetId": "pkt-sos-7712-9901",
    "callsign": "ALPHA-1",
    "alertType": "CRITICAL_SOS_BROADCAST",
    "latitude": 17.3850,
    "longitude": 78.4867
  }
}
```

#### 3. TRANSCEIVER_JOINED_CHANNEL (Presence Update)
Broadcast when a peer unit joins the tactical net.

```json
{
  "event": "TRANSCEIVER_JOINED_CHANNEL",
  "callsign": "BRAVO-2",
  "timestamp": 1727375202000,
  "data": {
    "channelId": "chan-cmd-net-01",
    "memberCount": 13
  }
}
```

#### 4. HEARTBEAT_ACK
Server acknowledgment to client keepalive frames.

```json
{
  "event": "HEARTBEAT_ACK",
  "callsign": "SERVER",
  "timestamp": 1727375200050,
  "data": {
    "status": "ALIVE"
  }
}
```

---

## 14. AI Model Management APIs

On-device neural inference uses quantized ONNX models stored locally on the Android handset. These endpoints distribute signed OTA model binaries and verify integrity.

### 14.1 Get Model Manifest

- **Method:** `GET`
- **Relative Path:** `/api/v1/models/manifest` (or alias `/api/v1/models`)
- **Full Production URL:** `https://itantra-c2-portal.onrender.com/api/v1/models/manifest`
- **Full Emulator URL:** `http://10.0.2.2:3000/api/v1/models/manifest`
- **Auth Required:** Yes

#### Response Body (`200 OK`)
```json
{
  "version": "2026.09.1",
  "models": [
    {
      "modelId": "whisper-base-int8-indic",
      "languageCode": "multilingual_10",
      "modelType": "STT_WHISPER",
      "fileSizeBytes": 45097152,
      "sha256Hash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
      "downloadUrl": "/api/v1/models/download/whisper-base-int8-indic"
    },
    {
      "modelId": "piper-indic-telugu-onnx",
      "languageCode": "te",
      "modelType": "TTS_PIPER",
      "fileSizeBytes": 22105920,
      "sha256Hash": "f2ca1bb6c7e907d06dafe4687e579fce76b37e4e93b7605022da52e6ccc26fd2",
      "downloadUrl": "/api/v1/models/download/piper-indic-telugu-onnx"
    }
  ]
}
```

---

### 14.2 Download Model Binary (HTTP Range Resumable)

- **Method:** `GET`
- **Relative Path:** `/api/v1/models/download/{modelId}`
- **Full Production URL:** `https://itantra-c2-portal.onrender.com/api/v1/models/download/{modelId}`
- **Full Emulator URL:** `http://10.0.2.2:3000/api/v1/models/download/{modelId}`
- **Auth Required:** Yes

#### Headers
Supports byte-range resumable HTTP/2 transfers:
```http
Authorization: Bearer <JWT_TOKEN>
Range: bytes=0-1048575
```

#### Response
- Returns `206 Partial Content` (for byte range requests) or `200 OK` (full stream).
- Returns `302 Found` redirect if redirected directly to MinIO/S3 object storage signed URLs.
- After download completion, verify the file with the expected `sha256Hash` before saving to local storage.

---

## 15. System Health Check

Verifies backend gateway availability and database connectivity.

- **Method:** `GET`
- **Relative Path:** `/api/healthz`
- **Full Production URL:** `https://itantra-c2-portal.onrender.com/api/healthz`
- **Full Emulator URL:** `http://10.0.2.2:3000/api/healthz`
- **Auth Required:** No

#### Response Body (`200 OK`)
```json
{
  "status": "HEALTHY",
  "timestamp": 1727375300000,
  "services": {
    "c2Portal": "UP",
    "streamGateway": "UP",
    "database": "UP",
    "jetstream": "UP"
  }
}
```

---

## 16. Local Voice Flow & Audio Pipeline

```text
       [Push-to-Talk (PTT) Button Pressed]
                       ↓
           [Audio Hardware Microphone]
                       ↓
         [Local Voice Activity Detector (VAD)]
                       ↓
     [Local On-Device STT (Vosk / Whisper ONNX)]
                       ↓
              [Recognized Unicode Text]
                       ↓
       [Compact Text Packet Assembly (<80 Bytes)]
                       ↓
  ┌────────────────────┴────────────────────┐
  │                                         │
[Local P2P Broadcast]              [Backend Uplink]
  │ (Wi-Fi Direct / BLE)             │ (WebSocket / REST Ingest)
  │                                         │
  └────────────────────┬────────────────────┘
                       ↓
             [Receiving Transceiver]
                       ↓
       [Local On-Device TTS (Piper Indic ONNX)]
                       ↓
        [Hardware Speaker / Tactical Headset]
```

---

## 17. Frontend ↔ Backend Responsibility Matrix

| Subsystem / Capability | Frontend (Flutter/Android) | Backend (Next.js / Node.js) | Notes |
|---|:---:|:---:|---|
| **Microphone & PTT Handling** | **YES** | NO | Low-latency hardware audio capture |
| **VAD (Voice Activity Detection)** | **YES** | NO | Energy/Silero local filtering |
| **On-Device STT Inference** | **YES** | NO | Whisper Int8 / Vosk local inference |
| **On-Device TTS Inference** | **YES** | NO | Piper Indic ONNX local audio generation |
| **Wi-Fi Direct / BLE Mesh** | **YES** | NO | Air-gapped decentralized transmission |
| **Local Offline Packet Queue** | **YES** | NO | SQLite/Hive local storage |
| **Device Registration** | UI & Keypair | **YES** | Challenge creation and verification |
| **JWT Issuance & Refresh** | Store securely | **YES** | Token lifecycle management |
| **Packet Ingest & Fanout** | Transmit packet | **YES** | Persistence in PostGIS & NATS JetStream |
| **Batch Sync Ingest** | Flush queue | **YES** | Idempotent bulk insertion |
| **Channel State & History** | UI & Selector | **YES** | PostgreSQL storage & Redis presence |
| **Real-Time Stream Gateway** | WebSocket client | **YES** | Sub/Pub relay on port 8443 / 443 |
| **Telemetry Ingest** | Collect metrics | **YES** | Battery/RSSI monitoring and alert triage |
| **Emergency SOS Triage** | SOS Red Alert | **YES** | Incident creation & NDMA webhook dispatch |
| **Incident Assignment/Resolution** | Status display | **YES** | First responder state machine |
| **AI Model OTA Distribution** | Download & Verify | **YES** | MinIO/S3 signed download URLs |

---

## 18. Recommended Flutter Architecture

```text
lib/
├── core/
│   ├── config/
│   │   └── api_config.dart               # Environment URLs (Production, Emulator, Edge)
│   ├── network/
│   │   ├── api_client.dart               # Dio/HTTP client with JWT & callsign interceptors
│   │   └── websocket_client.dart         # WebSocket client with heartbeat & reconnect
│   ├── auth/
│   │   └── token_storage.dart            # FlutterSecureStorage for JWT & keys
│   └── storage/
│       └── offline_queue_repository.dart # SQLite/Hive for offline packet backlog
├── services/
│   ├── auth_service.dart                 # Register, Token, Refresh flows
│   ├── transmission_service.dart         # Ingest & Sync API calls
│   ├── telemetry_service.dart            # Periodic battery/RSSI reporting
│   ├── sos_service.dart                  # Emergency SOS trigger & active alerts
│   ├── channel_service.dart              # Channel list, join, message history
│   └── model_manager_service.dart        # Manifest query, resumable download, SHA-256
├── ai/
│   ├── vad_service.dart                  # Voice activity detector
│   ├── stt_service.dart                  # Local STT (Vosk / Whisper ONNX)
│   └── tts_service.dart                  # Local TTS (Piper Indic ONNX)
└── features/
    ├── transceiver/                      # PTT button, active transmission HUD
    ├── channels/                         # Channel picker & membership
    ├── incidents/                        # SOS active alerts HUD & emergency map
    └── settings/                         # Call sign, server URL selector, model status
```

---

## 19. Integration Order for Developers

1. **Configure Environment:** Set up `ApiConfig` with `https://itantra-c2-portal.onrender.com` or local `http://10.0.2.2:3000`.
2. **Device Registration & Token Flow:** Call `POST /api/v1/auth/register` and `POST /api/v1/auth/token`. Store token in secure storage.
3. **HTTP Client Interceptor:** Configure `Authorization: Bearer <TOKEN>` and `x-transceiver-callsign: <CALLSIGN>`.
4. **Channels Discovery:** Call `GET /api/v1/channels` to populate channel switcher UI.
5. **WebSocket Gateway:** Connect to `wss://itantra-stream-gateway.onrender.com/v1/transceiver/channel`, subscribe to channel, and start 30s heartbeat.
6. **PTT & Packet Transmission:** Wire up PTT to `POST /api/v1/ingest` and WebSocket `INGEST_PACKET`.
7. **Incoming Message Handling:** Listen for `INGEST_PACKET_RECEIVED` on WebSocket and feed to local TTS.
8. **Catch-up History:** Implement `GET /api/v1/channels/{channelId}/messages` on reconnect.
9. **Offline Backlog Sync:** Queue packets offline; call `POST /api/v1/transmissions/sync` upon reconnection.
10. **Telemetry Reporting:** Schedule periodic `POST /api/v1/telemetry` reports.
11. **Emergency SOS:** Wire red alert button to `POST /api/v1/sos` and listen for `CRITICAL_SOS_TRIGGERED`.
12. **AI Model OTA:** Query `GET /api/v1/models/manifest` and download missing voice models.

---

## 20. HTTP Status & Error Handling Reference

| HTTP Status | Meaning | Client Action |
|:---:|---|---|
| `200 OK` | Request succeeded | Process returned JSON payload |
| `201 Created` | Resource created (e.g., Ingest, Register, SOS) | Store returned resource identifiers |
| `206 Partial Content` | Model download byte-range chunk | Append bytes to local disk cache |
| `400 Bad Request` | Invalid payload or missing fields | Check JSON schema & parameters |
| `401 Unauthorized` | Invalid/missing JWT token or callsign | Renew token via `/api/v1/auth/refresh` or re-authenticate |
| `403 Forbidden` | Callsign not authorized for channel/operation | Display permission alert in UI |
| `404 Not Found` | Channel, incident, or model ID does not exist | Verify resource ID |
| `409 Conflict` | Duplicate transmission packet ID | Mark local packet as already synced |
| `500 Server Error` | Backend exception | Log error, queue transmission for retry |
| `503 Service Unavailable` | Gateway or database rebooting | Back off exponentially, retry after 5–10s |

---

## 21. Frontend Integration Checklist

- [ ] **Authentication & Security**
  - [ ] Device registration flow (`POST /api/v1/auth/register`)
  - [ ] Token issuance (`POST /api/v1/auth/token`)
  - [ ] Token refresh handling (`POST /api/v1/auth/refresh`)
  - [ ] Secure storage for Bearer JWT and callsign header
- [ ] **Messaging & Channels**
  - [ ] Channel list retrieval (`GET /api/v1/channels`)
  - [ ] Channel join / assignment (`POST /api/v1/channels`)
  - [ ] WebSocket connection & channel subscription (`SUBSCRIBE`)
  - [ ] 30-second ping/pong heartbeat (`HEARTBEAT`)
  - [ ] Normal packet transmission (`POST /api/v1/ingest` and WS `INGEST_PACKET`)
  - [ ] Incoming transmission reception (`INGEST_PACKET_RECEIVED`)
  - [ ] Paginated message history catch-up (`GET /api/v1/channels/{channelId}/messages`)
- [ ] **Offline Operation**
  - [ ] Local SQLite/Hive packet queue
  - [ ] Connection state listener
  - [ ] Batch backlog sync on reconnect (`POST /api/v1/transmissions/sync`)
- [ ] **Telemetry & Health**
  - [ ] Periodic device health reporting (`POST /api/v1/telemetry`)
- [ ] **Emergency SOS**
  - [ ] One-touch red SOS alert trigger (`POST /api/v1/sos` and WS `CRITICAL_SOS`)
  - [ ] Incoming SOS handler (`CRITICAL_SOS_TRIGGERED`) with max-volume audio alarm
  - [ ] Active incidents screen (`GET /api/v1/incidents/active`)
  - [ ] Incident responder assignment & resolution UI (`PATCH /api/v1/incidents/{incidentId}`)
- [ ] **AI Models**
  - [ ] Model manifest query (`GET /api/v1/models/manifest`)
  - [ ] Range-resumable download (`GET /api/v1/models/download/{modelId}`)
  - [ ] SHA-256 integrity verification before mounting ONNX models
