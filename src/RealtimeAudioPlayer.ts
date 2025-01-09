import { AudioFormat } from "./RealtimeAudio.types";

export declare class RealtimeAudioPlayer {
  constructor(audioFormat: AudioFormat);

  public addBuffer(base64EncodedAudio: string): Promise<void>;
  public pause(): Promise<void>;
  public resume(): Promise<void>;
  public stop(): Promise<void>;
}
