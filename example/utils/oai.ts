import OpenAI from "openai-react-native";

const client = new OpenAI({
  baseURL: "https://api.openai.com/v1",
  apiKey: process.env.EXPO_PUBLIC_OPENAI_API_KEY
});

export function streamCompletion(
  prompt: string,
  systemPrompt: string,
  onTranscriptChunk: (transcriptChunk: string) => void,
  onAudioData: (data: string) => void
) {
  client.chat.completions.stream(
    {
      model: "gpt-4o-audio-preview",
      modalities: ["text", "audio"],
      audio: { voice: "alloy", format: "pcm16" },
      messages: [
        {
          "role": "system",
          "content": systemPrompt
        },
        {
          role: "user",
          content: prompt
        }
      ]
    },
    (data) => {
      // @ts-ignore
      const audio = data.choices[0].delta?.audio;
      if (audio) {
        if (audio?.transcript) {
          onTranscriptChunk(audio?.transcript);
        }
        if (audio?.data) {
          onAudioData(audio?.data);
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

}