import { ViewProps } from "react-native";
import { Ref } from "react";

export type RealtimeAudioModuleEvents = {
  onPlaybackStarted: () => void;
  onPlaybackStopped: () => void;
};

export type ChangeEventPayload = {
  value: string;
};

export type RealtimeAudioViewRef = {
  pause: () => void;
  resume: () => void;
  stop: () => void;
  addBuffer: (base64EncodedAudio: string) => void;
}

export enum AudioEncoding {
  pcm16bitInteger = "pcm16bitInteger",
  pcm32bitInteger = "pcm32bitInteger",
  pcm32bitFloat = "pcm32bitFloat",
  pcm64bitFloat = "pcm64bitFloat",
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
