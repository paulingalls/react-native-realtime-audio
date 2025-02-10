# React Native Realtime Audio

A React Native Expo module for real-time audio playback and recording, as well as visualization of both.
This module provides components for streaming and playing audio buffers in real-time, with optional waveform visualization.
It also includes components for recording audio buffers in real-time, with optional waveform visualization.

## Requirements
- Node 22 (for support of bun in corepack)
- Expo SDK 50 or higher
- iOS 15.1 or higher
- Android API level 26 or higher

## Installation

```bash
bunx expo install react-native-realtime-audio
```
or
```bash
npx expo install react-native-realtime-audio
```

## Features

- Real-time audio playback from base64-encoded buffers
- Real-time audio recording to base64-encoded buffers
- Configurable sample rate, audio encoding, and channel count
- Support for echo cancellation and noise suppression
- Support for VAD (Voice Activity Detection)
- Built-in waveform visualization component for both playback and recording
- Support for multiple visualizations 
- Simple, easy-to-use API

## Components

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
### RealtimeAudioPlayer

A class that handles real-time audio playback from base64-encoded buffers.

#### Constructor Parameters

- `sampleRate` (number): The sample rate of the audio in Hz (e.g., 44100, 48000)
- `encoding` (AudioEncoding): The audio encoding format (e.g., 'pcm16', 'float32')
- `channelCount` (number): Number of audio channels (1 for mono, 2 for stereo)

#### Methods
- `addBuffer(base64EncodedAudio: string): void`: Adds a base64-encoded audio buffer to the player;
- `pause(): void`: Pauses the audio playback;
- `resume(): void`: Resumes the audio playback;
- `stop(): void`: Stops the audio playback, and resets the player.

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

### RealtimeAudioPlayerView

Extends the functionality of RealtimeAudioPlayer by adding a visual waveform representation of the audio being played.

#### Props

AudioFormat:
- `sampleRate` (number): The sample rate of the audio in Hz (e.g., 44100, 48000)
- `encoding` (AudioEncoding): The audio encoding format (e.g., 'pcm16', 'float32')
- `channelCount` (number): Number of audio channels (1 for mono, 2 for stereo)

Other Props:
- `waveformColor` (string): Color of the waveform (default: '#00F')
- `visualizer` (Visualizers): Type of visualizer to use (e.g., 'barGraph', 'linearWaveform', 'circularWaveform', 'tripleCircle')
- `onPlaybackStarted` (function): Called when playback starts
- `onPlaybackStopped` (function): Called when playback stops

#### Ref Methods
- `addBuffer(base64EncodedAudio: string): void`: Adds a base64-encoded audio buffer to the player;
- `pause(): void`: Pauses the audio playback;
- `resume(): void`: Resumes the audio playback;
- `stop(): void`: Stops the audio playback, and resets the player.

#### Example Usage

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

### RealtimeAudioRecorder

A class that handles real-time audio recording to base64-encoded buffers.

#### Constructor Parameters

- `sampleRate` (number): The sample rate of the audio in Hz (e.g., 24000, 44100, 48000)
- `encoding` (AudioEncoding): The audio encoding format (e.g., 'pcm16', 'float32')
- `channelCount` (number): Number of audio channels (1 for mono, 2 for stereo)
- `echoCancellationEnabled` (boolean): Enable or disable echo cancellation

#### Methods
- `startRecording(): void`: Starts the audio recording;
- `stopRecording(): void`: Stops the audio recording, and delivers all recorded buffers.

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
}, true);

const audioPayload = useEvent(RealtimeAudioRecorderModule, "onAudioCaptured");
audioPayload && console.log("Audio captured in recorder, do something");
useEventListener(RealtimeAudioRecorderModule, "onCaptureComplete", () => {
    console.log("Recording complete, all buffers delivered");
});

recorder.startRecording();
recorder.stopRecording();
```

### RealtimeAudioRecorderView

Extends the functionality of RealtimeAudioRecorder by adding a visual waveform representation of the audio being recorded.

#### Props

AudioFormat:
- `sampleRate` (number): The sample rate of the audio in Hz (e.g., 44100, 48000)
- `encoding` (AudioEncoding): The audio encoding format (e.g., 'pcm16', 'float32')
- `channelCount` (number): Number of audio channels (1 for mono, 2 for stereo)

Other Props:
- `waveformColor` (string): Color of the waveform (default: '#00F')
- `visualizer` (Visualizers): Type of visualizer to use (e.g., 'barGraph', 'linearWaveform', 'circularWaveform', 'tripleCircle') 
- `echoCancellationEnabled` (boolean): Enable or disable echo cancellation
- `onAudioCaptured` (function): Called frequently with a base64 encoded audio buffer
- `onCaptureComplete` (function): Called when recording is complete and all buffers sent

#### Ref Methods
- `startRecording(): void`: Starts the audio recording;
- `stopRecording(): void`: Stops the audio recording, and delivers all recorded buffers.

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
      visualizer={Visualizers.linearWaveform}
      echoCancellationEnabled={true}
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

### RealtimeAudioVADRecorder

A class that handles real-time audio recording to base64-encoded buffers, but only when voice is present.

#### Constructor Parameters

- `sampleRate` (number): The sample rate of the audio in Hz (e.g., 24000, 44100, 48000)
- `encoding` (AudioEncoding): The audio encoding format (e.g., 'pcm16', 'float32')
- `channelCount` (number): Number of audio channels (1 for mono, 2 for stereo)
- `echoCancellationEnabled` (boolean): Enable or disable echo cancellation

#### Methods
- `startListening(): void`: Starts listening for voice activity;
- `stopListening(): void`: Stops listening for voice activity, and delivers all recorded buffers.


#### Example Usage

```javascript
import {
  RealtimeAudioVADRecorder,
  RealtimeAudioVADRecorderModule 
} from 'react-native-realtime-audio';
import { useEvent, useEventListener } from "expo";

const recorder: RealtimeAudioRecorder = new RealtimeAudioRecorderModule.RealtimeAudioVADRecorder({
  sampleRate: 24000,
  encoding: AudioEncoding.pcm16bitInteger,
  channelCount: 1
}, true);

const audioPayload = useEvent(RealtimeAudioVADRecorderModule, "onVoiceCaptured");
audioPayload && console.log("Voice captured in recorder, do something");
useEventListener(RealtimeAudioVADRecorderModule, "onVoiceStarted", () => {
    console.log("Voice started event");
});
useEventListener(RealtimeAudioVADRecorderModule, "onVoiceEnded", () => {
  console.log("Voice ended event");
});

recorder.startListening();
recorder.stopListening();
```

### RealtimeAudioVADRecorderView

Extends the functionality of RealtimeAudioVADRecorder by adding a visual waveform representation of the voice being recorded.

#### Props

AudioFormat:
- `sampleRate` (number): The sample rate of the audio in Hz (e.g., 44100, 48000)
- `encoding` (AudioEncoding): The audio encoding format (e.g., 'pcm16', 'float32')
- `channelCount` (number): Number of audio channels (1 for mono, 2 for stereo)

Other Props:
- `waveformColor` (string): Color of the waveform (default: '#00F')
- `visualizer` (Visualizers): Type of visualizer to use (e.g., 'barGraph', 'linearWaveform', 'circularWaveform', 'tripleCircle')
- `echoCancellationEnabled` (boolean): Enable or disable echo cancellation
- `onVoiceCaptured` (function): Called frequently with a base64 encoded audio buffer
- `onVoiceStarted` (function): Called when a voice is detected
- `onVoiceEnded` (function): Called when voice ends

#### Ref Methods
- `startListening(): void`: Starts listening for voice activity;
- `stopListening(): void`: Stops listening for voice activity, and delivers all recorded buffers.


#### Example Usage

```javascript
import {
  RealtimeAudioVADRecorderView,
  RealtimeAudioVADRecorderViewRef
} from 'react-native-realtime-audio';

function AudioVisualizer() {
  const recorderViewRef = useRef < RealtimeAudioVADRecorderViewRef > (null);

  // in a callback somewhere
  recorderViewRef.current?.startListening();

  return (
    <RealtimeAudioVADRecorderView
      ref={recorderViewRef}
      waveformColor={"#0F0"}
      audioFormat={{
        sampleRate: 24000,
        encoding: AudioEncoding.pcm16bitInteger,
        channelCount: 1
      }}
      visualizer={Visualizers.linearWaveform}
      echoCancellationEnabled={true}
      onVoiceCaptured={(event: { nativeEvent: RealtimeAudioCapturedEventPayload }) => {
        if (event && event.nativeEvent !== null && event.nativeEvent.audioBuffer) {
          const buffer = event.nativeEvent.audioBuffer;
          console.log("Audio captured in view, do something");
        }
      }}
      onVoiceStarted="" {() => {
      console.log("Voice started event");
    }}
      onVoiceEnded="" {() => {
        console.log("Voice ended event");
      }}
      style={styles.view}
    />
  );
}
```

## Example App

The example app demonstrates how to use the RealtimeAudioPlayerView, RealtimeAudioRecorderView and RealtimeAudioVADRecorderView components to play and record audio in real-time, with waveform visualization.
It also demonstrates how to use the RealtimeAudioPlayer, RealtimeAudioRecorder and RealtimeAudioVADRecorder classes directly.
Read the code in the different tabs to see how to use the components.
Just CD to the example directory and run the following commands:

```bash
bun install
bun run android
bun run ios
```

## License

MIT

## Support

For issues and feature requests, please file an issue on the GitHub repository.