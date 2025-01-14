import android.graphics.Color
import android.media.AudioFormat
import expo.modules.kotlin.records.Field
import expo.modules.kotlin.records.Record
import expo.modules.kotlin.types.Enumerable
import java.nio.ByteBuffer
import java.nio.ByteOrder

enum class AudioEncoding(val value: String) : Enumerable {
    pcm16bitInteger("pcm16bitInteger"),
    pcm32bitInteger("pcm32bitInteger"),
    pcm32bitFloat("pcm32bitFloat"),
    pcm64bitFloat("pcm64bitFloat")
}


class AudioFormatSettings : Record {
    @Field
    val sampleRate: Int = 24000

    @Field
    val encoding: AudioEncoding = AudioEncoding.pcm16bitInteger

    @Field
    val channelCount: Int = 1
}

fun getAndroidColor(hexString: String): Int {
    val cleanString = hexString.trim().lowercase()
    if (cleanString[0] == '#' && cleanString.length == 4) {
        val r = cleanString[1].toString().repeat(2).toInt(16)
        val g = cleanString[2].toString().repeat(2).toInt(16)
        val b = cleanString[3].toString().repeat(2).toInt(16)
        return Color.rgb(r, g, b)
    }
    return Color.parseColor(cleanString)
}

fun mapAudioEncodingToFormat(encoding: AudioEncoding): Int {
    return when (encoding) {
        AudioEncoding.pcm16bitInteger -> AudioFormat.ENCODING_PCM_16BIT
        AudioEncoding.pcm32bitInteger -> AudioFormat.ENCODING_PCM_32BIT
        AudioEncoding.pcm32bitFloat -> AudioFormat.ENCODING_PCM_FLOAT
        AudioEncoding.pcm64bitFloat -> AudioFormat.ENCODING_PCM_FLOAT
    }
}

fun mapChannelCountToOutputFormat(channelCount: Int): Int {
    if (channelCount == 2) return AudioFormat.CHANNEL_OUT_STEREO
    return AudioFormat.CHANNEL_OUT_MONO
}

fun mapChannelCountToInputFormat(channelCount: Int): Int {
    if (channelCount == 2) return AudioFormat.CHANNEL_IN_STEREO
    return AudioFormat.CHANNEL_IN_MONO
}

fun convertByteArrayToFloatArray(byteArray: ByteArray): FloatArray {
    val shortArray = ByteBuffer.wrap(byteArray).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
    val floatArray = FloatArray(shortArray.remaining())
    for (i in floatArray.indices) {
        floatArray[i] = shortArray.get(i).toFloat() / Short.MAX_VALUE
    }
    return floatArray
}

