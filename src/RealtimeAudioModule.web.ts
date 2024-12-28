import { registerWebModule, NativeModule } from 'expo';

import { RealtimeAudioModuleEvents } from './RealtimeAudio.types';

class RealtimeAudioModule extends NativeModule<RealtimeAudioModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
}

export default registerWebModule(RealtimeAudioModule);
