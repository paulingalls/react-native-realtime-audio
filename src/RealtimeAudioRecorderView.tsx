import { requireNativeView } from "expo";
import { ComponentType } from "react";
import { RealtimeAudioRecorderViewProps } from "./RealtimeAudio.types";

const RealtimeAudioRecorderView: ComponentType<RealtimeAudioRecorderViewProps> =
  requireNativeView("RealtimeAudioRecorder");

export default RealtimeAudioRecorderView;
