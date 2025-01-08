# RealtimeAudio

A React Native Expo module for real-time audio playback and visualization. This module provides components for streaming and playing audio buffers in real-time, with optional waveform visualization.

## Installation

```bash
npx expo install realtime-audio
```

## Features

- Real-time audio playback from base64-encoded buffers
- Configurable sample rate, audio encoding, and channel count
- Built-in waveform visualization component
- Low-latency streaming capabilities
- Simple, easy-to-use API

## Components

### RealtimeAudioView

Extends the functionality of RealtimeAudioPlayer by adding a visual waveform representation of the audio being played.

#### Props

AudioFormat:
- `sampleRate` (number): The sample rate of the audio in Hz (e.g., 44100, 48000)
- `encoding` (AudioEncoding): The audio encoding format (e.g., 'pcm16', 'float32')
- `channelCount` (number): Number of audio channels (1 for mono, 2 for stereo)
- `interleaved` (boolean): For multichannel, whether the audio data is interleaved (default: true)

Other Props:
- `waveformColor` (string): Color of the waveform (default: '#00F')
- `onPlaybackStarted` (function): Called when playback starts
- `onPlaybackStopped` (function): Called when playback stops

#### Example Usage

```javascript
import { RealtimeAudioView } from 'realtime-audio';

function AudioVisualizer() {
  const audioViewRef = useRef<RealtimeAudioViewRef>(null);

  // in a callback somewhere
  audioViewRef.current?.addBuffer(audio?.data);

  return (
    <RealtimeAudioView
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
- `interleaved` (boolean): For multichannel, whether the audio data is interleaved (default: true)

#### Example Usage

```javascript
import RealtimeAudio from 'react-native-realtime-audio';

const player = new RealtimeAudio.RealtimeAudioPlayer({
  sampleRate: 24000,
  encoding: AudioEncoding.pcm16bitInteger,
  channelCount: 1,
  interleaved: false
});

player.addBuffer(audio?.data);

```


## API Reference

### Playing Audio Buffers

Both components accept base64-encoded audio buffers through their `playBuffer` method:

```javascript
// Example of playing a buffer
const audioComponent = useRef(null);

// Play a base64-encoded audio buffer
audioComponent.current.playBuffer(base64EncodedAudioData);
```

### Event Handlers

- `onPlaybackStarted`: Called when buffers are available for playback
- `onPlaybackStopped`: Called when buffers are no longer available for playback

## Supported Formats

- Sample Rates: 8000Hz - 48000Hz (current tested with 24000Hz)
- Encodings: pcm16, float32 (currently tested with pcm16)
- Channel Counts: 1 (mono), 2 (stereo) (currently tested with mono)

## Requirements

- Expo SDK 50 or higher
- iOS 15.1 or higher
- Android API level 26 or higher

## License

MIT

## Support

For issues and feature requests, please file an issue on the GitHub repository.