package com.paulingalls.realtimeaudio

import android.graphics.Canvas

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
