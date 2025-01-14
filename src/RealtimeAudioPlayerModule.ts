import { NativeModule, requireNativeModule } from 'expo';

import { RealtimeAudioPlayerModuleEvents } from './RealtimeAudio.types';

declare class RealtimeAudioModule extends NativeModule<RealtimeAudioPlayerModuleEvents> {
}

// This call loads the native module object from the JSI.
export default requireNativeModule<RealtimeAudioModule>('RealtimeAudioPlayer');
