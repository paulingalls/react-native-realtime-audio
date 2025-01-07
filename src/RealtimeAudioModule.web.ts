import { registerWebModule, NativeModule } from 'expo';

import { RealtimeAudioModuleEvents } from './RealtimeAudio.types';

class RealtimeAudioModule extends NativeModule<RealtimeAudioModuleEvents> {
}

export default registerWebModule(RealtimeAudioModule);
