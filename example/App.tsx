import { useEvent } from "expo";
import RealtimeAudio, { AudioEncoding, RealtimeAudioView, RealtimeAudioViewRef } from "realtime-audio";
import { Button, SafeAreaView, ScrollView, Text, View } from "react-native";
import { useRef, useState } from "react";
import OpenAI from "openai-react-native";

const client = new OpenAI({
  baseURL: "https://api.openai.com/v1",
  apiKey: process.env.EXPO_PUBLIC_OPENAI_API_KEY
});

export default function App() {
  const onChangePayload = useEvent(RealtimeAudio, "onChange");
  const waveformRef = useRef<RealtimeAudioViewRef>(null);
  const [transcript, setTranscript] = useState<string>("");

  const playAudio = async () => {
    console.log("Playing audio...");
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
            content: "Will you please tell me about the history of Hello World in programming?"
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
            waveformRef.current?.addBuffer(audio?.data);
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
  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.container}>
        <Text style={styles.header}>Module API Example</Text>
        <Group name="Constants">
          <Text>{RealtimeAudio.PI}</Text>
        </Group>
        <Group name="Functions">
          <Text>{RealtimeAudio.hello()}</Text>
        </Group>
        <Group name="Async functions">
          <Button
            title="Set value"
            onPress={async () => {
              await RealtimeAudio.setValueAsync("Hello from JS!");
            }}
          />
        </Group>
        <Group name="Events">
          <Text>{onChangePayload?.value}</Text>
        </Group>
        <Group name="Views">
          <Button
            title="Play Audio"
            onPress={async () => {
              await playAudio();
            }}
          />
          <RealtimeAudioView
            ref={waveformRef}
            waveformColor={"#000"}
            audioFormat={{ sampleRate: 24000, encoding: AudioEncoding.pcm16bitInteger, channelCount: 1, interleaved: false }}
            onPlaybackStarted={() => console.log("Playback started Callback")}
            onPlaybackStopped={() => console.log("Playback stopped Callback")}
            style={styles.view}
          />
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
    height: 200
  }
};
