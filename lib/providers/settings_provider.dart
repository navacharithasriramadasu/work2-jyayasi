import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection_model.dart';
import '../models/device_model.dart';

class SettingsStateModel {
  final CommunicationMode communicationMode;
  final ConnectionType preferredTransport;
  final bool onDeviceStt;
  final bool onDeviceTts;
  final bool cloudProcessing;
  final String aiModelName;
  final String inferenceMode;
  final bool localVoiceProcessingOnly;

  const SettingsStateModel({
    this.communicationMode = CommunicationMode.walkieTalkie,
    this.preferredTransport = ConnectionType.wifiDirect,
    this.onDeviceStt = true,
    this.onDeviceTts = true,
    this.cloudProcessing = false,
    this.aiModelName = 'Auto (Whisper-Tiny / Piper-Int8)',
    this.inferenceMode = 'Optimized (FP16 / Int8)',
    this.localVoiceProcessingOnly = true,
  });

  SettingsStateModel copyWith({
    CommunicationMode? communicationMode,
    ConnectionType? preferredTransport,
    bool? onDeviceStt,
    bool? onDeviceTts,
    bool? cloudProcessing,
    String? aiModelName,
    String? inferenceMode,
    bool? localVoiceProcessingOnly,
  }) {
    return SettingsStateModel(
      communicationMode: communicationMode ?? this.communicationMode,
      preferredTransport: preferredTransport ?? this.preferredTransport,
      onDeviceStt: onDeviceStt ?? this.onDeviceStt,
      onDeviceTts: onDeviceTts ?? this.onDeviceTts,
      cloudProcessing: cloudProcessing ?? this.cloudProcessing,
      aiModelName: aiModelName ?? this.aiModelName,
      inferenceMode: inferenceMode ?? this.inferenceMode,
      localVoiceProcessingOnly:
          localVoiceProcessingOnly ?? this.localVoiceProcessingOnly,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsStateModel> {
  @override
  SettingsStateModel build() {
    return const SettingsStateModel();
  }

  void setCommunicationMode(CommunicationMode mode) {
    state = state.copyWith(communicationMode: mode);
  }

  void setPreferredTransport(ConnectionType transport) {
    state = state.copyWith(preferredTransport: transport);
  }

  void toggleCloudProcessing(bool value) {
    state = state.copyWith(cloudProcessing: value);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsStateModel>(
  SettingsNotifier.new,
);
