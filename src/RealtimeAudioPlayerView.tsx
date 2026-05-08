import { requireNativeView } from "expo";
import { ComponentType } from "react";
import { RealtimeAudioPlayerViewProps } from "./RealtimeAudio.types";

const RealtimeAudioPlayerView: ComponentType<RealtimeAudioPlayerViewProps> =
  requireNativeView("RealtimeAudioPlayer");

export default RealtimeAudioPlayerView;
