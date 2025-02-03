import { AudioFormat } from "./RealtimeAudio.types";

export declare class RealtimeAudioVADRecorder {
  constructor(audioFormat: AudioFormat, echoCancellationEnabled: boolean);

  public startListening(): Promise<void>;
  public stopListening(): Promise<void>;
}