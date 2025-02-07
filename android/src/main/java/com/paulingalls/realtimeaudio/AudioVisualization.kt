package com.paulingalls.realtimeaudio

import android.graphics.Canvas
import kotlin.math.min

interface AudioVisualization {
    fun getSampleChunksFromAudio(
        buffer: FloatArray,
        channelCount: Int,
        chunkSize: Int
    ): ArrayList<FloatArray>

    fun updateData(data: FloatArray)
    fun draw(canvas: Canvas, width: Float, height: Float)
    fun setColor(color: Int)
}

abstract class BaseVisualization : AudioVisualization {
    override fun getSampleChunksFromAudio(
        buffer: FloatArray,
        channelCount: Int,
        chunkSize: Int
    ): ArrayList<FloatArray> {
        val frameLength = buffer.size / channelCount
        val pieceCount = frameLength / chunkSize
        val samplePieces = ArrayList<FloatArray>()

        for (pieceIndex in 0 until pieceCount) {
            val pieceSamples = mutableListOf<Float>()

            val startIndex = pieceIndex * chunkSize
            val endIndex = min(startIndex + chunkSize, frameLength)

            for (i in startIndex until endIndex) {
                var sample = 0f
                for (channel in 0 until channelCount) {
                    sample += buffer[i * channelCount + channel]
                }
                sample /= channelCount.toFloat()
                pieceSamples.add(sample)
            }
            samplePieces.add(pieceSamples.toFloatArray())
        }

        if (frameLength % chunkSize != 0) {
            val remainingSamples = mutableListOf<Float>()

            val startIndex = pieceCount * chunkSize

            for (i in startIndex until frameLength) {
                var sample = 0f
                for (channel in 0 until channelCount) {
                    sample += buffer[i * channelCount + channel]
                }
                sample /= channelCount.toFloat()
                remainingSamples.add(sample)
            }
            samplePieces.add(remainingSamples.toFloatArray())
        }

        return samplePieces
    }

}