/// Core state machines for transceiver operation.
library;

enum CommunicationState {
  idle,
  listening,
  processing,
  messageReady,
  sending,
  sent,
  receiving,
  speaking,
  error,
}

enum ConnectionStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

enum EmergencyState {
  idle,
  confirming,
  sending,
  sent,
  received,
  speaking,
  error,
}

enum CommunicationMode {
  walkieTalkie, // Push to talk
  continuous,   // Normal continuous communication
}
