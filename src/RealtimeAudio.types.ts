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

export enum AudioEncoding {
  pcm16bitInteger = "pcm16bitInteger",
  pcm32bitInteger = "pcm32bitInteger",
  pcm32bitFloat = "pcm32bitFloat",
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
  onPlaybackStarted?: () => void;
  onPlaybackStopped?: () => void;
} & ViewProps;

export type RealtimeAudioRecorderViewProps = {
  audioFormat: AudioFormat;
  ref?: Ref<RealtimeAudioRecorderViewRef>;
  waveformColor?: string;
  echoCancellationEnabled?: boolean;
  onAudioCaptured?: (event: { nativeEvent: RealtimeAudioCapturedEventPayload }) => void;
  onCaptureComplete?: () => void;
} & ViewProps;