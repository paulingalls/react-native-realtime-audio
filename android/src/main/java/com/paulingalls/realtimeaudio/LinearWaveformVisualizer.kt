package com.paulingalls.realtimeaudio

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import kotlin.math.max

class LinearWaveformVisualizer : BaseVisualization() {
    private val waveformPaint: Paint = Paint()
    private val waveformPath: Path = Path()

    init {
        waveformPaint.apply {
            color = Color.BLUE
            style = Paint.Style.STROKE
            strokeWidth = 2f
            isAntiAlias = true
        }
    }

    override fun draw(canvas: Canvas, width: Float, height: Float) {
        if (samples.isEmpty()) return

        val centerY = height / 2
        waveformPath.reset()
        val step = max(1, samples.size / width.toInt())
        var x = 0f

        waveformPath.moveTo(0f, centerY)

        for (i in samples.indices step step) {
            val sampleValue = samples[i]
            val y = centerY + (sampleValue * height / 2)
            waveformPath.lineTo(x, y)
            x += width / (samples.size / step)
        }

        canvas.drawPath(waveformPath, waveformPaint)
    }

    override fun setColor(color: Int) {
        waveformPaint.color = color
    }
}