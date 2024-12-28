import * as React from 'react';

import { RealtimeAudioViewProps } from './RealtimeAudio.types';

export default function RealtimeAudioView(props: RealtimeAudioViewProps) {
  return (
    <div>
      <iframe
        style={{ flex: 1 }}
        src={props.url}
        onLoad={() => props.onLoad({ nativeEvent: { url: props.url } })}
      />
    </div>
  );
}
