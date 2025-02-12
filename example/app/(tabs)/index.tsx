import { Button, SafeAreaView, ScrollView, StyleSheet, Text, View } from "react-native";
import {
  AudioEncoding,
  RealtimeAudioModule,
  RealtimeAudioPlayer,
  RealtimeAudioPlayerModule,
  RealtimeAudioPlayerView,
  RealtimeAudioPlayerViewRef,
  Visualizers
} from "react-native-realtime-audio";
import { Group } from "../../components/group";
import { useEffect, useRef, useState } from "react";
import { useEventListener } from "expo";
import { streamCompletion } from "../../utils/oai";

export default function Tab() {
  const audioViewRef = useRef<RealtimeAudioPlayerViewRef>(null);
  const playerRef = useRef<RealtimeAudioPlayer>(null);
  const [transcript, setTranscript] = useState<string>("");

  useEventListener(RealtimeAudioPlayerModule, "onPlaybackStarted", () => {
    console.log("RealtimeAudio playback started event");
  });
  useEventListener(RealtimeAudioPlayerModule, "onPlaybackStopped", () => {
    console.log("RealtimeAudio playback stopped event");
  });

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
    streamCompletion(
      "In what language was the first Hello World program written?",
      "You are an experienced programmer",
      (transcriptChunk) => {
        setTranscript((prev) => prev + transcriptChunk);
      },
      (audioData) => {
        playerRef.current?.addBuffer(audioData);
      }
    );
  };

  const playAudioInView = async () => {
    console.log("Playing audio in view...");
    setTranscript("");
    streamCompletion(
      "Who was responsible for the first Hello World program?",
      "You are an experienced programmer",
      (transcriptChunk) => {
        setTranscript((prev) => prev + transcriptChunk);
      },
      (audioData) => {
        audioViewRef.current?.addBuffer(audioData);
      }
    );
  };

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
        <Text style={styles.header}>Playback Examples</Text>
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
            waveformColor= {"#9ec7f4"}
            visualizer={Visualizers.tripleCircle}
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

const styles = StyleSheet.create({
  header: {
    fontSize: 30,
    margin: 10,
    textAlign: "center"
  },
  container: {
    flex: 1,
    backgroundColor: "#eee"
  },
  view: {
    flex: 1,
    marginTop: 10,
    height: 300,
    borderWidth: 1,
    borderColor: "gray",
    borderRadius: 5,
    borderStyle: "solid",
    backgroundColor: "#0e2655"
  }
});
