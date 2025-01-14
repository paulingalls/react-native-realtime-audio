import { requireNativeView } from 'expo';
import { RealtimeAudioPlayerViewProps, RealtimeAudioPlayerViewRef } from "./RealtimeAudio.types";
import { ComponentType, forwardRef, Ref } from "react";

const NativeView: ComponentType<RealtimeAudioPlayerViewProps> =
  requireNativeView('RealtimeAudioPlayer');

const RealtimeAudioPlayerView =
  forwardRef((props: RealtimeAudioPlayerViewProps, ref: Ref<RealtimeAudioPlayerViewRef>) => {
  return <NativeView {...props} ref={ref} />;
});

export default RealtimeAudioPlayerView;
