import { Button, SafeAreaView, ScrollView, StyleSheet, Text, View } from "react-native";
import { useEffect, useRef, useState } from "react";
import {
  AudioEncoding,
  RealtimeAudioCapturedEventPayload,
  RealtimeAudioPlayerView,
  RealtimeAudioPlayerViewRef,
  RealtimeAudioRecorder,
  RealtimeAudioRecorderModule,
  RealtimeAudioRecorderView,
  RealtimeAudioRecorderViewRef
} from "react-native-realtime-audio";
import { useEvent, useEventListener } from "expo";
import { Group } from "../../components/group";

export default function Tab() {
  const audioViewRef = useRef<RealtimeAudioPlayerViewRef>(null);
  const recorderViewRef = useRef<RealtimeAudioRecorderViewRef>(null);
  const recorderRef = useRef<RealtimeAudioRecorder>(null);
  const [recordedBuffers, setRecordedBuffers] = useState<string[]>([]);

  const audioPayload = useEvent(RealtimeAudioRecorderModule, "onAudioCaptured");
  useEventListener(RealtimeAudioRecorderModule, "onCaptureComplete", () => {
    console.log("RealtimeAudio capture complete");
    for (const buffer of recordedBuffers) {
      audioViewRef.current?.addBuffer(buffer);
    }
    setRecordedBuffers([]);
  });

  const stopRecordingAudio = async () => {
    console.log("Stopping recording audio...");
    await recorderRef.current?.stopRecording();
  };

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

  useEffect(() => {
    if (audioPayload) {
      console.log("Audio payload received");
      setRecordedBuffers((prev) => [...prev, audioPayload.audioBuffer]);
    }
  }, [audioPayload]);

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.container}>
        <Text style={styles.header}>Recording Examples</Text>
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
        <Group name="RealtimeAudioPlayerView">
          <View style={{ flexDirection: "row", justifyContent: "space-between" }}>
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
    height: 100,
    borderWidth: 1,
    borderColor: "gray",
    borderRadius: 5,
    borderStyle: "solid",
    backgroundColor: "#eee"
  }
});
