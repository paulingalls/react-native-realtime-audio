import { ViewProps } from "react-native";
import { Ref } from "react";

export type RealtimeAudioModuleEvents = {
  onChange: (params: ChangeEventPayload) => void;
};

export type ChangeEventPayload = {
  value: string;
};

export type RealtimeAudioViewRef = {
  play: () => void;
  pause: () => void;
  stop: () => void;
  addBuffer: (base64EncodedAudio: string) => void;
  setAudioFormat: (sampleRate: number, bitsPerSample: number, channels: number) => void;
}

export type RealtimeAudioViewProps = {
  ref?: Ref<RealtimeAudioViewRef>;
  waveformColor?: string;
  onPlaybackStarted?: () => void;
  onPlaybackStopped?: () => void;
} & ViewProps;
