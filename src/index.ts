// Reexport the native module. On web, it will be resolved to RealtimeAudioModule.web.ts
// and on native platforms to RealtimeAudioModule.ts
export { default as RealtimeAudioModule } from './RealtimeAudioModule';
export { default as RealtimeAudioPlayerModule } from './RealtimeAudioPlayerModule';
export { default as RealtimeAudioRecorderModule } from './RealtimeAudioRecorderModule';
export { default as RealtimeAudioVADRecorderModule } from './RealtimeAudioVADRecorderModule';
export { default as RealtimeAudioPlayerView } from './RealtimeAudioPlayerView';
export { default as RealtimeAudioRecorderView } from './RealtimeAudioRecorderView';
export { default as RealtimeAudioVADRecorderView } from './RealtimeAudioVADRecorderView';
export * from './RealtimeAudio.types';
export * from './RealtimeAudioPlayer';
export * from './RealtimeAudioRecorder';
export * from './RealtimeAudioVADRecorder';
