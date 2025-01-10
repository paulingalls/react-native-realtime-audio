// Reexport the native module. On web, it will be resolved to RealtimeAudioModule.web.ts
// and on native platforms to RealtimeAudioModule.ts
export { default as RealtimeAudioModule } from './RealtimeAudioModule';
export { default as RealtimeAudioRecorderModule } from './RealtimeAudioRecorderModule';
export { default as RealtimeAudioView } from './RealtimeAudioView';
export { default as RealtimeAudioRecorderView } from './RealtimeAudioRecorderView';
export * from './RealtimeAudio.types';
export * from './RealtimeAudioPlayer';
export * from './RealtimeAudioRecorder';
