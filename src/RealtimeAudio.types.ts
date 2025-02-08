import { ViewProps } from "react-native";
import { Ref } from "react";

export type RealtimeAudioPlayerModuleEvents = {
  onPlaybackStarted: () => void;
  onPlaybackStopped: () => void;
};

export type RealtimeAudioRecorderModuleEvents = {
  onAudioCaptured: (payload: RealtimeAudioCapturedEventPayload) => void;
  onCaptureComplete: () => void;
}

export type RealtimeAudioVADRecorderModuleEvents = {
  onVoiceCaptured: (payload: RealtimeAudioCapturedEventPayload) => void;
  onVoiceStarted: () => void;
  onVoiceEnded: () => void;
}

export type RealtimeAudioCapturedEventPayload = {
  audioBuffer: string;
};

export type RealtimeAudioPlayerViewRef = {
  pause: () => void;
  resume: () => void;
  stop: () => void;
  addBuffer: (base64EncodedAudio: string) => void;
}

export type RealtimeAudioRecorderViewRef = {
  startRecording: () => void;
  stopRecording: () => void;
}

export type RealtimeAudioVADRecorderViewRef = {
  startListening: () => void;
  stopListening: () => void;
}

export enum AudioEncoding {
  pcm16bitInteger = "pcm16bitInteger",
  pcm32bitFloat = "pcm32bitFloat",
}

export enum Visualizers {
  barGraph = "barGraph",
  linearWaveform = "linearWaveform",
  circularWaveform = "circularWaveform",
  tripleCircle = "tripleCircle",
}

export type AudioFormat = {
  sampleRate: number;
  encoding: AudioEncoding;
  channelCount: number;
}

export type RealtimeAudioPlayerViewProps = {
  audioFormat: AudioFormat;
  ref?: Ref<RealtimeAudioPlayerViewRef>;
  waveformColor?: string;
  visualizer?: Visualizers;
  onPlaybackStarted?: () => void;
  onPlaybackStopped?: () => void;
} & ViewProps;

export type RealtimeAudioRecorderViewProps = {
  audioFormat: AudioFormat;
  ref?: Ref<RealtimeAudioRecorderViewRef>;
  waveformColor?: string;
  visualizer?: Visualizers;
  echoCancellationEnabled?: boolean;
  onAudioCaptured?: (event: { nativeEvent: RealtimeAudioCapturedEventPayload }) => void;
  onCaptureComplete?: () => void;
} & ViewProps;

export type RealtimeAudioVADRecorderViewProps = {
  audioFormat: AudioFormat;
  ref?: Ref<RealtimeAudioVADRecorderViewRef>;
  waveformColor?: string;
  visualizer?: Visualizers;
  echoCancellationEnabled?: boolean;
  onVoiceCaptured?: (event: { nativeEvent: RealtimeAudioCapturedEventPayload }) => void;
  onVoiceStarted?: () => void;
  onVoiceEnded?: () => void;
} & ViewProps;