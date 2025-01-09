import { AudioFormat } from "./RealtimeAudio.types";

export declare class RealtimeAudioRecorder {
  constructor(audioFormat: AudioFormat);

  public startRecording(): Promise<void>;
  public stopRecording(): Promise<void>;
}