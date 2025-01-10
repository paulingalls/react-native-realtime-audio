import { ViewProps } from "react-native";
import { Ref } from "react";

export type RealtimeAudioModuleEvents = {
  onPlaybackStarted: () => void;
  onPlaybackStopped: () => void;
};

export type RealtimeAudioRecorderModuleEvents = {
  onAudioCaptured: (payload: RealtimeAudioCapturedEventPayload) => void;
}

export type RealtimeAudioCapturedEventPayload = {
  audioBuffer: string;
};

export type RealtimeAudioViewRef = {
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
  interleaved: boolean;
}

export type RealtimeAudioViewProps = {
  audioFormat: AudioFormat;
  ref?: Ref<RealtimeAudioViewRef>;
  waveformColor?: string;
  onPlaybackStarted?: () => void;
  onPlaybackStopped?: () => void;
} & ViewProps;

export type RealtimeAudioRecorderViewProps = {
  audioFormat: AudioFormat;
  ref?: Ref<RealtimeAudioRecorderViewRef>;
  waveformColor?: string;
  onAudioCaptured?: (event: { nativeEvent: RealtimeAudioCapturedEventPayload }) => void;
} & ViewProps;