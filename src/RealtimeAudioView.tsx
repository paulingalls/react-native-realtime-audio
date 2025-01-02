import { requireNativeView } from 'expo';
import { RealtimeAudioViewProps, RealtimeAudioViewRef } from "./RealtimeAudio.types";
import { ComponentType, forwardRef, Ref } from "react";

const NativeView: ComponentType<RealtimeAudioViewProps> =
  requireNativeView('RealtimeAudio');

const RealtimeAudioView =
  forwardRef((props: RealtimeAudioViewProps, ref: Ref<RealtimeAudioViewRef>) => {
  return <NativeView {...props} ref={ref} />;
});

export default RealtimeAudioView;
