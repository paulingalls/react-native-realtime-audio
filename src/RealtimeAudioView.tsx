import { requireNativeView } from 'expo';
import * as React from 'react';

import { RealtimeAudioViewProps } from './RealtimeAudio.types';

const NativeView: React.ComponentType<RealtimeAudioViewProps> =
  requireNativeView('RealtimeAudio');

export default function RealtimeAudioView(props: RealtimeAudioViewProps) {
  return <NativeView {...props} />;
}
