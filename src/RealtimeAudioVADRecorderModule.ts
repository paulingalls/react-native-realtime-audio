import { NativeModule, requireNativeModule } from 'expo';

import { RealtimeAudioVADRecorderModuleEvents } from './RealtimeAudio.types';

declare class RealtimeAudioVADRecorderModule extends NativeModule<RealtimeAudioVADRecorderModuleEvents> {
}

// This call loads the native module object from the JSI.
export default requireNativeModule<RealtimeAudioVADRecorderModule>('RealtimeAudioVADRecorder');
