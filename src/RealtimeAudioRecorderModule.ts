import { NativeModule, requireNativeModule } from 'expo';

import { RealtimeAudioRecorderModuleEvents } from './RealtimeAudio.types';

declare class RealtimeAudioRecorderModule extends NativeModule<RealtimeAudioRecorderModuleEvents> {
}

// This call loads the native module object from the JSI.
export default requireNativeModule<RealtimeAudioRecorderModule>('RealtimeAudioRecorder');
