import { requireNativeView } from "expo";
import {
  RealtimeAudioVADRecorderViewProps,
  RealtimeAudioVADRecorderViewRef
} from "./RealtimeAudio.types";
import { ComponentType, forwardRef, Ref } from "react";

const NativeView: ComponentType<RealtimeAudioVADRecorderViewProps> =
  requireNativeView("RealtimeAudioVADRecorder");

const RealtimeAudioVADRecorderView =
  forwardRef((props: RealtimeAudioVADRecorderViewProps, ref: Ref<RealtimeAudioVADRecorderViewRef>) => {
    return <NativeView {...props} ref={ref} />;
  });

export default RealtimeAudioVADRecorderView;
