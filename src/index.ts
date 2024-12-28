// Reexport the native module. On web, it will be resolved to RealtimeAudioModule.web.ts
// and on native platforms to RealtimeAudioModule.ts
export { default } from './RealtimeAudioModule';
export { default as RealtimeAudioView } from './RealtimeAudioView';
export * from  './RealtimeAudio.types';
