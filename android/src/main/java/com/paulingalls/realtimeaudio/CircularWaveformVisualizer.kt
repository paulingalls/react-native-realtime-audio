package com.paulingalls.realtimeaudio

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import kotlin.math.cos
import kotlin.math.sin

class CircularWaveformVisualizer : BaseVisualization() {
    private val paint = Paint()
    private val path = Path()
    private var rotation: Float = 0f
    private var colorShift: Float = 0f
    private var samples: FloatArray = floatArrayOf()
    private var hue: Float = 210f

    override fun updateData(data: FloatArray) {
        this.samples = data
    }

    override fun draw(canvas: Canvas, width: Float, height: Float) {
        if (samples.isEmpty()) return

        val centerX = width / 2
        val centerY = height / 2
        val maxRadius = minOf(centerX, centerY) - 10

        path.reset()
        path.moveTo(centerX, centerY)

        for (i in samples.indices) {
            val amplitude = samples[i]
            val angle = (i * 2 * Math.PI / samples.size + rotation).toFloat()
            val radius = maxRadius * amplitude
            val x = centerX + (cos(angle.toDouble()) * radius).toFloat()
            val y = centerY + (sin(angle.toDouble()) * radius).toFloat()
            path.lineTo(x, y)
        }

        path.close()

        paint.color = Color.HSVToColor(255, floatArrayOf((hue + sin(colorShift.toDouble()) * 20).toFloat(), 0.8f, 0.6f))
        paint.style = Paint.Style.FILL_AND_STROKE
        paint.strokeWidth = 2f
        canvas.drawPath(path, paint)

        rotation += 0.002f
        colorShift += 0.005f
    }

    override fun setColor(color: Int) {
        val hsv = floatArrayOf(0f, 0f, 0f)
        Color.colorToHSV(color, hsv)
        hue = hsv[0]
    }
}
