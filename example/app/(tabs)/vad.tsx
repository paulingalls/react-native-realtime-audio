import { Button, SafeAreaView, ScrollView, StyleSheet, Text, View } from "react-native";
import { Group } from "../../components/group";
import { useEffect, useRef, useState } from "react";
import {
  AudioEncoding,
  RealtimeAudioCapturedEventPayload,
  RealtimeAudioPlayerView,
  RealtimeAudioPlayerViewRef,
  RealtimeAudioVADRecorder,
  RealtimeAudioVADRecorderModule,
  RealtimeAudioVADRecorderViewRef
} from "react-native-realtime-audio";
import { useEvent, useEventListener } from "expo";
import RealtimeAudioVADRecorderView from "react-native-realtime-audio/RealtimeAudioVADRecorderView";

export default function Tab() {
  const audioViewRef = useRef<RealtimeAudioPlayerViewRef>(null);
  const vadRecorderRef = useRef<RealtimeAudioVADRecorder>(null);
  const vadRecorderViewRef = useRef<RealtimeAudioVADRecorderViewRef>(null);
  const [recordedBuffers, setRecordedBuffers] = useState<string[]>([]);
  const [hasVoice, setHasVoice] = useState<boolean>(false);
  const [isListening, setIsListening] = useState<boolean>(false);

  const vadPayload = useEvent(RealtimeAudioVADRecorderModule, "onVoiceCaptured");

  useEventListener(RealtimeAudioVADRecorderModule, "onVoiceEnded", () => {
    console.log("RealtimeAudio VAD detected voice ended event");
    for (const buffer of recordedBuffers) {
      audioViewRef.current?.addBuffer(buffer);
    }
    setRecordedBuffers([]);
    setHasVoice(false);
  });
  useEventListener(RealtimeAudioVADRecorderModule, "onVoiceStarted", () => {
    console.log("RealtimeAudio VAD detected voice started event");
    setHasVoice(true);
  });

  const listenForVoice = async () => {
    console.log("Listening for voice...");
    if (vadRecorderRef.current === null) {
      // @ts-ignore
      vadRecorderRef.current = new RealtimeAudioVADRecorderModule.RealtimeAudioVADRecorder({
        sampleRate: 24000,
        encoding: AudioEncoding.pcm16bitInteger,
        channelCount: 1
      }, true) as RealtimeAudioVADRecorder;
    }
    await vadRecorderRef.current?.startListening();
    setIsListening(true);
  };

  const stopListeningForVoice = async () => {
    console.log("Stopping listening for voice...");
    await vadRecorderRef.current?.stopListening();
    setIsListening(false);
  };

  useEffect(() => {
    if (vadPayload) {
      console.log("VAD payload received");
      setRecordedBuffers((prev) => [...prev, vadPayload.audioBuffer]);
    }
  }, [vadPayload]);

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.container}>
        <Text style={styles.header}>VAD Example</Text>
        <Text style={styles.voice}>
          {isListening ? `Listening - ${hasVoice ? "VOICE" : "NO VOICE"}` : "Not Listening"}
        </Text>
        <Group name="RealtimeAudioVADRecorder">
          <View style={{ flexDirection: "row", justifyContent: "space-evenly" }}>
            <Button
              title="Listen for Voice"
              onPress={async () => {
                await listenForVoice();
              }}
            />
            <Button
              title="Stop Listening"
              onPress={async () => {
                await stopListeningForVoice();
              }}
            />
          </View>
        </Group>
        <Group name="RealtimeAudioVADRecorderView">
          <View style={{ flexDirection: "row", justifyContent: "space-evenly" }}>
            <Button
              title="Listen for Voice"
              onPress={() => {
                console.log("Starting listening in view...");
                vadRecorderViewRef.current?.startListening();
                setIsListening(true)
              }}
            />
            <Button
              title="Stop Listening"
              onPress={() => {
                console.log("Stopping listening in view...");
                vadRecorderViewRef.current?.stopListening();
                setIsListening(false)
              }}
            />
          </View>
          <RealtimeAudioVADRecorderView
            ref={vadRecorderViewRef}
            waveformColor={"#0e2655"}
            echoCancellationEnabled={true}
            audioFormat={{
              sampleRate: 24000,
              encoding: AudioEncoding.pcm16bitInteger,
              channelCount: 1
            }}
            onVoiceCaptured={(event: { nativeEvent: RealtimeAudioCapturedEventPayload }) => {
              if (event && event.nativeEvent !== null && event.nativeEvent.audioBuffer) {
                const buffer = event.nativeEvent.audioBuffer;
                console.log("Voice captured in view");
                setRecordedBuffers((prev) => {
                  return [...prev, buffer];
                });
              }
            }}
            onVoiceEnded={() => {
              console.log("RealtimeAudio VAD detected voice ended event");
              for (const buffer of recordedBuffers) {
                audioViewRef.current?.addBuffer(buffer);
              }
              setRecordedBuffers([]);
              setHasVoice(false);
            }}
            onVoiceStarted={() => {
              console.log("RealtimeAudio VAD detected voice started event");
              audioViewRef.current?.stop();
              setHasVoice(true);
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
  voice: {
    textAlign: "center",
    fontWeight: "bold",
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
