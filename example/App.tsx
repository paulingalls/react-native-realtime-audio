import { useEvent, useEventListener } from "expo";
import {
  RealtimeAudioModule,
  RealtimeAudioPlayerModule,
  RealtimeAudioRecorderModule,
  AudioEncoding,
  RealtimeAudioPlayerView,
  RealtimeAudioRecorderView,
  RealtimeAudioPlayerViewRef,
  RealtimeAudioPlayer,
  RealtimeAudioRecorder,
  RealtimeAudioRecorderViewRef,
  RealtimeAudioCapturedEventPayload
} from "react-native-realtime-audio";
import { Button, SafeAreaView, ScrollView, Text, View } from "react-native";
import { useEffect, useRef, useState } from "react";
import OpenAI from "openai-react-native";

const client = new OpenAI({
  baseURL: "https://api.openai.com/v1",
  apiKey: process.env.EXPO_PUBLIC_OPENAI_API_KEY
});

export default function App() {
  const audioViewRef = useRef<RealtimeAudioPlayerViewRef>(null);
  const recorderViewRef = useRef<RealtimeAudioRecorderViewRef>(null);
  const recorderRef = useRef<RealtimeAudioRecorder>(null);
  const playerRef = useRef<RealtimeAudioPlayer>(null);
  const [transcript, setTranscript] = useState<string>("");
  const [recordedBuffers, setRecordedBuffers] = useState<string[]>([]);
  const audioPayload = useEvent(RealtimeAudioRecorderModule, "onAudioCaptured");
  useEventListener(RealtimeAudioRecorderModule, "onCaptureComplete", () => {
    for (const buffer of recordedBuffers) {
      audioViewRef.current?.addBuffer(buffer);
    }
    setRecordedBuffers([]);
  });
  useEventListener(RealtimeAudioPlayerModule, "onPlaybackStarted", () => {
    console.log("RealtimeAudio playback started event");
  });
  useEventListener(RealtimeAudioPlayerModule, "onPlaybackStopped", () => {
    console.log("RealtimeAudio playback stopped event");
  });

  const recordAudio = async () => {
    console.log("Recording audio...");
    if (recorderRef.current === null) {
      // @ts-ignore
      recorderRef.current = new RealtimeAudioRecorderModule.RealtimeAudioRecorder({
        sampleRate: 24000,
        encoding: AudioEncoding.pcm16bitInteger,
        channelCount: 1
      }, false) as RealtimeAudioRecorder;
    }
    await recorderRef.current?.startRecording();
  };

  const stopRecordingAudio = async () => {
    console.log("Stopping recording audio...");
    await recorderRef.current?.stopRecording();
  };

  const playAudio = async () => {
    console.log("Playing audio...");
    setTranscript("");
    if (playerRef.current === null) {
      // @ts-ignore
      playerRef.current = new RealtimeAudioPlayerModule.RealtimeAudioPlayer({
        sampleRate: 24000,
        encoding: AudioEncoding.pcm16bitInteger,
        channelCount: 1
      });
    }
    client.chat.completions.stream(
      {
        model: "gpt-4o-audio-preview",
        modalities: ["text", "audio"],
        audio: { voice: "alloy", format: "pcm16" },
        messages: [
          {
            "role": "system",
            "content": "You are an experienced programmer"
          },
          {
            role: "user",
            content: "In what language was the first Hello World program written?"
          }
        ]
      },
      (data) => {
        // @ts-ignore
        const audio = data.choices[0].delta?.audio;
        if (audio) {
          if (audio?.transcript) {
            setTranscript((prev) => prev + audio?.transcript);
          }
          if (audio?.data) {
            playerRef.current?.addBuffer(audio?.data);
          }
        }
      },
      {
        onError: (error) => {
          console.error("SSE Error:", error); // Handle any errors here
        },
        onOpen: () => {
          console.log("SSE connection for completion opened."); // Handle when the connection is opened
        }
      }
    );
  };

  const playAudioInView = async () => {
    console.log("Playing audio in view...");
    setTranscript("");
    client.chat.completions.stream(
      {
        model: "gpt-4o-audio-preview",
        modalities: ["text", "audio"],
        audio: { voice: "alloy", format: "pcm16" },
        messages: [
          {
            "role": "system",
            "content": "You are an experienced programmer."
          },
          {
            role: "user",
            content: "Who was responsible for the first Hello World program?"
          }
        ]
      },
      (data) => {
        // @ts-ignore
        const audio = data.choices[0].delta?.audio;
        if (audio) {
          if (audio?.transcript) {
            setTranscript((prev) => prev + audio?.transcript);
          }
          if (audio?.data) {
            audioViewRef.current?.addBuffer(audio?.data);
          }
        }
      },
      {
        onError: (error) => {
          console.error("SSE Error:", error); // Handle any errors here
        },
        onOpen: () => {
          console.log("SSE connection for completion opened."); // Handle when the connection is opened
        }
      }
    );
  };

  useEffect(() => {
    if (audioPayload) {
      console.log("Audio payload received");
      setRecordedBuffers((prev) => [...prev, audioPayload.audioBuffer]);
    }
  }, [audioPayload]);

  useEffect(() => {
    const checkPermissions = async () => {
      const result = await RealtimeAudioModule.checkAndRequestAudioPermissions();
      console.log("Permissions result", result);
    };
    checkPermissions().then(() => console.log("Permissions checked."));
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.container}>
        <Text style={styles.header}>Module API Example</Text>
        <Group name="RealtimeAudioRecorder">
          <View style={{ flexDirection: "row", justifyContent: "space-evenly" }}>
            <Button
              title="Record Audio"
              onPress={async () => {
                await recordAudio();
              }}
            />
            <Button
              title="Stop"
              onPress={async () => {
                await stopRecordingAudio();
              }}
            />
          </View>
        </Group>
        <Group name="RealtimeAudioRecorderView">
          <View style={{ flexDirection: "row", justifyContent: "space-evenly" }}>
            <Button
              title="Record Audio"
              onPress={() => {
                console.log("Starting recording in view...");
                recorderViewRef.current?.startRecording();
                console.log("Recording started in view.");
              }}
            />
            <Button
              title="Stop"
              onPress={() => {
                console.log("Stopping recording in view...");
                recorderViewRef.current?.stopRecording();
              }}
            />
          </View>
          <RealtimeAudioRecorderView
            ref={recorderViewRef}
            waveformColor={"#0e2655"}
            echoCancellationEnabled={true}
            audioFormat={{
              sampleRate: 24000,
              encoding: AudioEncoding.pcm16bitInteger,
              channelCount: 1
            }}
            onAudioCaptured={(event: { nativeEvent: RealtimeAudioCapturedEventPayload }) => {
              if (event && event.nativeEvent !== null && event.nativeEvent.audioBuffer) {
                const buffer = event.nativeEvent.audioBuffer;
                console.log("Audio captured in view");
                setRecordedBuffers((prev) => {
                  return [...prev, buffer];
                });
              }
            }}
            onCaptureComplete={() => {
              for (const buffer of recordedBuffers) {
                audioViewRef.current?.addBuffer(buffer);
              }
              setRecordedBuffers([]);
            }}
            style={styles.view}
          />
        </Group>
        <Group name="RealtimeAudioPlayer">
          <View style={{ flexDirection: "row", justifyContent: "space-between" }}>
            <Button
              title="Play"
              onPress={async () => {
                await playAudio();
              }}
            />
            <Button
              title="Pause"
              onPress={() => {
                console.log("Pausing playback...");
                playerRef.current?.pause();
              }}
            />
            <Button
              title="Resume"
              onPress={() => {
                console.log("Resuming playback...");
                playerRef.current?.resume();
              }}
            />
            <Button
              title="Stop"
              onPress={() => {
                console.log("Stopping playback...");
                playerRef.current?.stop();
              }}
            />
          </View>
        </Group>
        <Group name="RealtimeAudioPlayerView">
          <View style={{ flexDirection: "row", justifyContent: "space-between" }}>
            <Button
              title="Play"
              onPress={async () => {
                await playAudioInView();
              }}
            />
            <Button
              title="Pause"
              onPress={() => {
                console.log("Pausing playback...");
                audioViewRef.current?.pause();
              }}
            />
            <Button
              title="Resume"
              onPress={() => {
                console.log("Resuming playback...");
                audioViewRef.current?.resume();
              }}
            />
            <Button
              title="Stop"
              onPress={() => {
                console.log("Stopping playback in view...");
                audioViewRef.current?.stop();
              }}
            />
          </View>
          <RealtimeAudioPlayerView
            ref={audioViewRef}
            waveformColor={"#2f93ff"}
            audioFormat={{
              sampleRate: 24000,
              encoding: AudioEncoding.pcm16bitInteger,
              channelCount: 1
            }}
            onPlaybackStarted={() => console.log("RealtimeAudioView playback started callback")}
            onPlaybackStopped={() => console.log("RealtimeAudioView playback stopped callback")}
            style={styles.view}
          />
        </Group>
        <Group name="Transcript">
          <Text>{transcript}</Text>
        </Group>
      </ScrollView>
    </SafeAreaView>
  );
}

function Group(props: { name: string; children: React.ReactNode }) {
  return (
    <View style={styles.group}>
      <Text style={styles.groupHeader}>{props.name}</Text>
      {props.children}
    </View>
  );
}

const styles = {
  header: {
    fontSize: 30,
    margin: 20
  },
  groupHeader: {
    fontSize: 20,
    marginBottom: 20
  },
  group: {
    margin: 20,
    backgroundColor: "#fff",
    borderRadius: 10,
    padding: 20
  },
  container: {
    flex: 1,
    backgroundColor: "#eee"
  },
  view: {
    flex: 1,
    marginTop: 10,
    height: 100,
    borderWidth: 1,
    borderColor: "gray",
    borderRadius: 5,
    borderStyle: "solid",
    backgroundColor: "#eee"
  }
};
