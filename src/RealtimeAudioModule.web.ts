import { registerWebModule, NativeModule } from 'expo';

import { RealtimeAudioPlayerModuleEvents } from './RealtimeAudio.types';

class RealtimeAudioModule extends NativeModule<RealtimeAudioPlayerModuleEvents> {
}

export default registerWebModule(RealtimeAudioModule);
