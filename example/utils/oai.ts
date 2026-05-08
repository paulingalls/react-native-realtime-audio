import OpenAI from "openai";
import { fetch as expoFetch } from "expo/fetch";

const client = new OpenAI({
  baseURL: "https://api.openai.com/v1",
  apiKey: process.env.EXPO_PUBLIC_OPENAI_API_KEY,
  // expo/fetch supports streaming response bodies, which RN's global fetch does not
  fetch: expoFetch as unknown as typeof fetch,
  dangerouslyAllowBrowser: true,
});

export async function streamCompletion(
  prompt: string,
  systemPrompt: string,
  onTranscriptChunk: (transcriptChunk: string) => void,
  onAudioData: (data: string) => void
) {
  const stream = await client.chat.completions.create({
    model: "gpt-4o-audio-preview",
    modalities: ["text", "audio"],
    audio: { voice: "alloy", format: "pcm16" },
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: prompt },
    ],
    stream: true,
  });

  for await (const chunk of stream) {
    const audio = (chunk.choices[0]?.delta as { audio?: { transcript?: string; data?: string } })?.audio;
    if (audio?.transcript) onTranscriptChunk(audio.transcript);
    if (audio?.data) onAudioData(audio.data);
  }
}
