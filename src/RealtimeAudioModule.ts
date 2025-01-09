import { NativeModule, requireNativeModule } from 'expo';

import { RealtimeAudioModuleEvents } from './RealtimeAudio.types';

declare class RealtimeAudioModule extends NativeModule<RealtimeAudioModuleEvents> {}

// This call loads the native module object from the JSI.
export default requireNativeModule<RealtimeAudioModule>('RealtimeAudio');
