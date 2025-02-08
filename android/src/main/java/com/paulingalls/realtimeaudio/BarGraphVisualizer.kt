package com.paulingalls.realtimeaudio

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import kotlin.math.abs
import kotlin.math.ceil


class BarGraphVisualizer : BaseVisualization() {
    private val paint = Paint()
    private var mainColor: Int = Color.BLUE

    override fun draw(canvas: Canvas, width: Float, height: Float) {
        val barCount = 20
        val minBarHeight = 20
        val barWidth = width / barCount
        val gap = 4.0
        val div = samples.size / barCount
        paint.strokeWidth = (barWidth - gap).toFloat()
        paint.color = mainColor

        for (i in 0 until barCount) {
            val bytePosition = ceil((i * div).toDouble()).toInt()
            val amplitude = abs(samples[bytePosition])
            val top = height - minBarHeight - (amplitude * (height - minBarHeight))
            val barX = (i * barWidth) + (barWidth / 2)
            canvas.drawLine(barX, height, barX, top, paint)
        }
    }

    override fun setColor(color: Int) {
        mainColor = color
    }
}