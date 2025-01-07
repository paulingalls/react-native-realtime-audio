# RealtimeAudio

A React Native Expo module for real-time audio playback and visualization. This module provides components for streaming and playing audio buffers in real-time, with optional waveform visualization.

## Installation

```bash
npx expo install realtime-audio
```

## Features

- Real-time audio playback from base64-encoded buffers
- Configurable sample rate, encoding, and channel count
- Built-in waveform visualization component
- Low-latency streaming capabilities
- Simple, easy-to-use API

## Components

### RealtimeAudioPlayer

A component that handles real-time audio playback from base64-encoded buffers.

#### Props

- `sampleRate` (number): The sample rate of the audio in Hz (e.g., 44100, 48000)
- `encoding` (string): The audio encoding format (e.g., 'pcm16', 'float32')
- `channelCount` (number): Number of audio channels (1 for mono, 2 for stereo)

#### Example Usage

```javascript
import { RealtimeAudioPlayer } from 'realtime-audio';

function AudioStreamPlayer() {
  return (
    <RealtimeAudioPlayer
      sampleRate={44100}
      encoding="pcm16"
      channelCount={1}
      onBuffer={(buffer) => {
        // Handle new audio buffer
      }}
    />
  );
}
```

### RealtimeAudioView

Extends the functionality of RealtimeAudioPlayer by adding a visual waveform representation of the audio being played.

#### Props

Includes all props from RealtimeAudioPlayer, plus:

- `waveformColor` (string): Color of the waveform (default: '#000000')
- `backgroundColor` (string): Background color of the visualization (default: 'transparent')
- `height` (number): Height of the waveform view in pixels
- `width` (number): Width of the waveform view in pixels

#### Example Usage

```javascript
import { RealtimeAudioView } from 'realtime-audio';

function AudioVisualizer() {
  return (
    <RealtimeAudioView
      sampleRate={44100}
      encoding="pcm16"
      channelCount={2}
      waveformColor="#2196F3"
      height={100}
      width={300}
      onBuffer={(buffer) => {
        // Handle new audio buffer
      }}
    />
  );
}
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

- `onBuffer`: Called when a new buffer is received
- `onError`: Called when an error occurs during playback
- `onPlaybackComplete`: Called when the current buffer has finished playing

## Supported Formats

- Sample Rates: 8000Hz - 48000Hz
- Encodings: pcm16, float32
- Channel Counts: 1 (mono), 2 (stereo)

## Performance Considerations

- Buffer sizes should be optimized for your use case. Smaller buffers provide lower latency but require more frequent updates
- For real-time applications, recommended buffer sizes are between 512 and 4096 samples
- The waveform visualization may impact performance on lower-end devices

## Requirements

- Expo SDK 45 or higher
- iOS 11.0 or higher
- Android API level 21 or higher

## License

MIT

## Contributing

Please read CONTRIBUTING.md for details on our code of conduct and the process for submitting pull requests.

## Support

For issues and feature requests, please file an issue on the GitHub repository.