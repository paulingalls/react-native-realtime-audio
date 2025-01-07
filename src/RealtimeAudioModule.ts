import { NativeModule, requireNativeModule } from 'expo';

import { RealtimeAudioModuleEvents, AudioFormat } from './RealtimeAudio.types';

declare class RealtimeAudioModule extends NativeModule<RealtimeAudioModuleEvents> {}

declare namespace RealtimeAudioModule {
  class RealtimeAudioPlayer {
    constructor(audioFormat: AudioFormat);

    public addBuffer(base64EncodedAudio: string): Promise<void>;
    public pause(): Promise<void>;
    public resume(): Promise<void>;
    public stop(): Promise<void>;
  }
}

// This call loads the native module object from the JSI.
export default requireNativeModule<RealtimeAudioModule>('RealtimeAudio');
