import { ViewProps } from "react-native";
import { Ref } from "react";

export type RealtimeAudioModuleEvents = {
  onChange: (params: ChangeEventPayload) => void;
};

export type ChangeEventPayload = {
  value: string;
};

export type RealtimeAudioViewRef = {
  pause: () => void;
  resume: () => void;
  stop: () => void;
  addBuffer: (base64EncodedAudio: string) => void;
  setAudioFormat: (sampleRate: number, bitsPerSample: number, channels: number) => void;
}

export enum AudioEncoding {
  pcm16bitInteger = "pcm16bitInteger",
  pcm32bitInteger = "pcm32bitInteger",
  pcm32bitFloat = "pcm32bitFloat",
  pcm64bitFloat = "pcm64bitFloat",
}

export type RealtimeAudioViewProps = {
  audioFormat: {
    sampleRate: number;
    encoding: AudioEncoding;
    channelCount: number;
    interleaved: boolean;
  }
  ref?: Ref<RealtimeAudioViewRef>;
  waveformColor?: string;
  onPlaybackStarted?: () => void;
  onPlaybackStopped?: () => void;
} & ViewProps;
