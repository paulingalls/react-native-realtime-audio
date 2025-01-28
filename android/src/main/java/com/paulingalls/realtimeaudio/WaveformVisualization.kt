package com.paulingalls.realtimeaudio

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

class WaveformVisualization : AudioVisualization {
    private val waveformPaint: Paint = Paint()
    private val waveformPath: Path = Path()
    private var waveformData: FloatArray = FloatArray(0)

    init {
        waveformPaint.apply {
            color = Color.BLUE
            style = Paint.Style.STROKE
            strokeWidth = 2f
            isAntiAlias = true
        }
    }

    override fun getSamplesFromAudio(buffer: FloatArray, channelCount: Int, sampleCount: Int): ArrayList<FloatArray> {
        val frameLength = buffer.size / channelCount
        val pieceCount = frameLength / sampleCount
        val samplePieces = ArrayList<FloatArray>()

        for (pieceIndex in 0 until pieceCount) {
            val pieceSamples = mutableListOf<Float>()

            val startIndex = pieceIndex * sampleCount
            val endIndex = min(startIndex + sampleCount, frameLength)

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

        if (frameLength % sampleCount != 0) {
            val remainingSamples = mutableListOf<Float>()

            val startIndex = pieceCount * sampleCount

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


    override fun updateData(data: FloatArray) {
        waveformData = data
    }

    override fun draw(canvas: Canvas, width: Float, height: Float) {
        if (waveformData.isEmpty()) return

        val centerY = height / 2
        waveformPath.reset()
        val step = max(1, waveformData.size / width.toInt())
        var x = 0f

        waveformPath.moveTo(0f, centerY)

        for (i in waveformData.indices step step) {
            val sampleValue = waveformData[i]
            val y = centerY + (sampleValue * height / 2)
            waveformPath.lineTo(x, y)
            x += width / (waveformData.size / step)
        }

        canvas.drawPath(waveformPath, waveformPaint)
    }

    override fun setColor(color: Int) {
        waveformPaint.color = color
    }
}