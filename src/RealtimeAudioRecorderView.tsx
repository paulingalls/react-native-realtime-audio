import { requireNativeView } from 'expo';
import {
  RealtimeAudioRecorderViewProps,
  RealtimeAudioRecorderViewRef,
  RealtimeAudioPlayerViewProps,
  RealtimeAudioPlayerViewRef
} from "./RealtimeAudio.types";
import { ComponentType, forwardRef, Ref } from "react";

const NativeView: ComponentType<RealtimeAudioRecorderViewProps> =
  requireNativeView('RealtimeAudioRecorder');

const RealtimeAudioRecorderView =
  forwardRef((props: RealtimeAudioRecorderViewProps, ref: Ref<RealtimeAudioRecorderViewRef>) => {
  return <NativeView {...props} ref={ref} />;
});

export default RealtimeAudioRecorderView;
