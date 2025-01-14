import { NativeModule, requireNativeModule } from 'expo';

declare class RealtimeAudioModule extends NativeModule {
  checkAndRequestAudioPermissions(): Promise<boolean>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<RealtimeAudioModule>('RealtimeAudio');
