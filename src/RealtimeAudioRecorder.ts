import { AudioFormat } from "./RealtimeAudio.types";

export declare class RealtimeAudioRecorder {
  constructor(audioFormat: AudioFormat, echoCancellationEnabled: boolean);

  public startRecording(): Promise<void>;
  public stopRecording(): Promise<void>;
}