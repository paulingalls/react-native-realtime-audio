# React Native Realtime Audio

A React Native Expo module for real-time audio playback and recording, as well as visualization of both.
This module provides components for streaming and playing audio buffers in real-time, with optional waveform visualization.
It also includes components for recording audio buffers in real-time, with optional waveform visualization.

## Installation

```bash
npx expo install react-native-realtime-audio
```

## Features

- Real-time audio playback from base64-encoded buffers
- Real-time audio recording to base64-encoded buffers
- Configurable sample rate, audio encoding, and channel count
- Built-in waveform visualization component for both playback and recording
- Simple, easy-to-use API

## Components

### RealtimeAudioPlayerView

Extends the functionality of RealtimeAudioPlayer by adding a visual waveform representation of the audio being played.

#### Props

AudioFormat:
- `sampleRate` (number): The sample rate of the audio in Hz (e.g., 44100, 48000)
- `encoding` (AudioEncoding): The audio encoding format (e.g., 'pcm16', 'float32')
- `channelCount` (number): Number of audio channels (1 for mono, 2 for stereo)

Other Props:
- `waveformColor` (string): Color of the waveform (default: '#00F')
- `onPlaybackStarted` (function): Called when playback starts
- `onPlaybackStopped` (function): Called when playback stops

#### Example Usage

### RealtimeAudioModule
You need to make sure that the app has permissions to use the microphone.  
You can do this by adding the following to your app.json file, or use the plugin
from the plugins folder.

```json
{
  "expo": {
    "android": {
      "permissions": [
        "RECORD_AUDIO"
      ]
    },
    "ios": {
      "infoPlist": {
        "NSMicrophoneUsageDescription": "This app uses the microphone to record audio."
      }
    }
  }
}
```
Here is the call to check the permissions.

```javascript
import { useEvent, useEventListener } from "expo";
import {
  RealtimeAudioModule,
} from 'react-native-realtime-audio';

useEffect(() => {
  const checkPermissions = async () => {
    const result = await RealtimeAudioModule.checkAndRequestAudioPermissions();
    console.log("Permissions result", result);
  };
  checkPermissions().then(() => console.log("Permissions checked."));
}, []);

```

### RealtimeAudioPlayerView

```javascript
import {
  RealtimeAudioPlayerView,
  RealtimeAudioPlayerViewRef
} from 'react-native-realtime-audio';

function AudioVisualizer() {
  const audioViewRef = useRef < RealtimeAudioPlayerViewRef > (null);

  // in a callback somewhere
  audioViewRef.current?.addBuffer(audio?.data);

  return (
    <RealtimeAudioPlayerView
      ref={audioViewRef}
      waveformColor={"#F00"}
      audioFormat={{
        sampleRate: 24000,
        encoding: AudioEncoding.pcm16bitInteger,
        channelCount: 1,
        interleaved: false
      }}
      onPlaybackStarted={() => console.log("RealtimeAudioView playback started")}
      onPlaybackStopped={() => console.log("RealtimeAudioView playback stopped")}
      style={styles.view}
    />
  );
}
```

### RealtimeAudioPlayer

A class that handles real-time audio playback from base64-encoded buffers.

#### Constructor Parameters

- `sampleRate` (number): The sample rate of the audio in Hz (e.g., 44100, 48000)
- `encoding` (AudioEncoding): The audio encoding format (e.g., 'pcm16', 'float32')
- `channelCount` (number): Number of audio channels (1 for mono, 2 for stereo)

#### Example Usage

```javascript
import {
  RealtimeAudioPlayer,
  RealtimeAudioPlayerModule 
} from 'react-native-realtime-audio';
import { useEventListener } from "expo";

const player: RealtimeAudioPlayer = new RealtimeAudioPlayerModule.RealtimeAudioPlayer({
  sampleRate: 24000,
  encoding: AudioEncoding.pcm16bitInteger,
  channelCount: 1
});

useEventListener(RealtimeAudioPlayerModule, "onPlaybackStarted", () => {
  console.log("RealtimeAudio playback started event");
});
useEventListener(RealtimeAudioPlayerModule, "onPlaybackStopped", () => {
  console.log("RealtimeAudio playback stopped event");
});

player.addBuffer(audio?.data);

player.pause()
player.resume()
player.stop()

```

### RealtimeAudiorecorderView

Extends the functionality of RealtimeAudioRecorder by adding a visual waveform representation of the audio being recorded.

#### Props

AudioFormat:
- `sampleRate` (number): The sample rate of the audio in Hz (e.g., 44100, 48000)
- `encoding` (AudioEncoding): The audio encoding format (e.g., 'pcm16', 'float32')
- `channelCount` (number): Number of audio channels (1 for mono, 2 for stereo)

Other Props:
- `waveformColor` (string): Color of the waveform (default: '#00F')
- `onAudioCaptured` (function): Called frequently with a base64 encoded audio buffer
- `onCaptureComplete` (function): Called when recording is complete and all buffers sent

#### Example Usage

```javascript
import {
  RealtimeAudioRecorderView,
  RealtimeAudioRecorderViewRef
} from 'react-native-realtime-audio';

function AudioVisualizer() {
  const recorderViewRef = useRef < RealtimeAudioRecorderViewRef > (null);

  // in a callback somewhere
  recorderViewRef.current?.startRecording();

  return (
    <RealtimeAudioRecorderView
      ref={recorderViewRef}
      waveformColor={"#0F0"}
      audioFormat={{
        sampleRate: 24000,
        encoding: AudioEncoding.pcm16bitInteger,
        channelCount: 1
      }}
      onAudioCaptured={(event: { nativeEvent: RealtimeAudioCapturedEventPayload }) => {
        if (event && event.nativeEvent !== null && event.nativeEvent.audioBuffer) {
          const buffer = event.nativeEvent.audioBuffer;
          console.log("Audio captured in view, do something");
        }
      }}
      onCaptureComplete={() => {
        console.log("Recording complete, all buffers delivered");
      }}
      style={styles.view}
    />
  );
}
```

### RealtimeAudioRecorder

A class that handles real-time audio recording to base64-encoded buffers.

#### Constructor Parameters

- `sampleRate` (number): The sample rate of the audio in Hz (e.g., 44100, 48000)
- `encoding` (AudioEncoding): The audio encoding format (e.g., 'pcm16', 'float32')
- `channelCount` (number): Number of audio channels (1 for mono, 2 for stereo)

#### Example Usage

```javascript
import {
  RealtimeAudioRecorder,
  RealtimeAudioRecorderModule 
} from 'react-native-realtime-audio';
import { useEvent, useEventListener } from "expo";

const recorder: RealtimeAudioRecorder = new RealtimeAudioRecorderModule.RealtimeAudioRecorder({
  sampleRate: 24000,
  encoding: AudioEncoding.pcm16bitInteger,
  channelCount: 1
});

const audioPayload = useEvent(RealtimeAudioRecorderModule, "onAudioCaptured");
audioPayload && console.log("Audio captured in recorder, do something");
useEventListener(RealtimeAudioRecorderModule, "onCaptureComplete", () => {
    console.log("Recording complete, all buffers delivered");
});

recorder.startRecording();
recorder.stopRecording();
```

## Example App

The example app demonstrates how to use the RealtimeAudioPlayerView and RealtimeAudioRecorderView components to play and record audio in real-time, with waveform visualization.
It also demonstrates how to use the RealtimeAudioPlayer and RealtimeAudioRecorder classes directly.
Read the code in App.tsx to see how to use the components.
Just CD to the example directory and run the following commands:

```bash
bun install
bun run android
bun run ios
```

## Requirements

- Expo SDK 50 or higher
- iOS 15.1 or higher
- Android API level 26 or higher

## License

MIT

## Support

For issues and feature requests, please file an issue on the GitHub repository.