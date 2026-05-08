import { requireNativeView } from "expo";
import { ComponentType } from "react";
import { RealtimeAudioVADRecorderViewProps } from "./RealtimeAudio.types";

const RealtimeAudioVADRecorderView: ComponentType<RealtimeAudioVADRecorderViewProps> =
  requireNativeView("RealtimeAudioVADRecorder");

export default RealtimeAudioVADRecorderView;
