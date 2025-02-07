package com.paulingalls.realtimeaudio

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RadialGradient
import android.graphics.Shader
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.sin

class TripleCircleVisualizer : BaseVisualization() {
    private var rotation: Float = 0f
    private var colorShift: Float = 0f
    private var samples: FloatArray = floatArrayOf()
    private var hue: Float = 210f
    private var mainColor: Int = Color.argb(255, 17, 24, 39)

    override fun updateData(data: FloatArray) {
        this.samples = data
    }

    override fun draw(canvas: Canvas, width: Float, height: Float) {
        val bufferLength = samples.size
        if (bufferLength == 0) return

        val paint = Paint().apply {
            isAntiAlias = true
        }

        // Clear with fade effect
        paint.style = Paint.Style.FILL
        paint.color = Color.argb((0.3 * 255).toInt(), Color.red(mainColor), Color.green(mainColor), Color.blue(mainColor))
        canvas.drawRect(0f, 0f, width, height, paint)

        val centerX = width / 2
        val centerY = height / 2
        val maxRadius = min(centerX, centerY) - 10

        // Draw outer circle
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 2f
        val baseHue = hue + sin(colorShift.toDouble()) * 20
        paint.color = Color.HSVToColor(floatArrayOf(baseHue.toFloat(), 0.8f, 0.6f))
        canvas.drawCircle(centerX, centerY, maxRadius, paint)

        // Define base colors with shifting hues
        val waveforms = listOf(
            Waveform(
                maxRadius * 0.8f,
                baseHue.toFloat(),
                90f,
                70f,
                floatArrayOf(baseHue.toFloat(), 90f, 0.7f, 0.3f),
                floatArrayOf(baseHue.toFloat(), 90f, 0.5f, 0f),
                rotation
            ),
            Waveform(
                maxRadius * 0.6f,
                baseHue.toFloat() + 10,
                85f,
                60f,
                floatArrayOf(baseHue.toFloat() + 10, 85f, 0.6f, 0.3f),
                floatArrayOf(baseHue.toFloat() + 10, 85f, 0.4f, 0f),
                rotation + (Math.PI * 2 / 3).toFloat()
            ),
            Waveform(
                maxRadius * 0.4f,
                baseHue.toFloat() + 20,
                80f,
                50f,
                floatArrayOf(baseHue.toFloat() + 20, 80f, 0.5f, 0.3f),
                floatArrayOf(baseHue.toFloat() + 20, 80f, 0.3f, 0f),
                rotation + (Math.PI * 4 / 3).toFloat()
            )
        )

        waveforms.forEach { waveform ->
            val points = mutableListOf<Pair<Float, Float>>()

            for (i in 0 until bufferLength) {
                val amplitude =
                    (samples[i % bufferLength] + 1) / 2.0f // Normalize float samples from -1.0 to 1.0 to 0.0 to 1.0
                val angle = (i * 2 * Math.PI / bufferLength).toFloat() + waveform.rotation

                val radius = waveform.baseRadius + (maxRadius * 0.4f * amplitude)
                val x = centerX + cos(angle) * radius
                val y = centerY + sin(angle) * radius

                points.add(Pair(x, y))
            }

            // Create gradient for fill
            val gradient = RadialGradient(
                centerX, centerY, waveform.baseRadius * 1.2f,
                intArrayOf(
                    Color.HSVToColor(waveform.gradientColors1),
                    Color.HSVToColor(waveform.gradientColors2)
                ),
                floatArrayOf(0f, 1f),
                Shader.TileMode.CLAMP
            )
            paint.shader = gradient
            paint.style = Paint.Style.FILL

            val path = Path()
            path.moveTo(centerX, centerY)
            points.forEach { (x, y) ->
                path.lineTo(x, y)
            }
            path.close()
            canvas.drawPath(path, paint)

            paint.shader = null
            paint.color = Color.HSVToColor(
                floatArrayOf(
                    waveform.hue,
                    waveform.saturation,
                    waveform.lightness
                )
            )
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = 2f

            val strokePath = Path()
            points.forEachIndexed { index, (x, y) ->
                if (index == 0) strokePath.moveTo(x, y) else strokePath.lineTo(x, y)
            }
            strokePath.close()
            canvas.drawPath(strokePath, paint)

            paint.setShadowLayer(
                15f,
                0f,
                0f,
                Color.HSVToColor(
                    floatArrayOf(
                        waveform.hue,
                        waveform.saturation,
                        waveform.lightness
                    )
                )
            )
        }

        // Ensure these variables are updated after each draw
        rotation += 0.002f
        colorShift += 0.005f
    }

    override fun setColor(color: Int) {
        mainColor = color
        val hsv = floatArrayOf(0f, 0f, 0f)
        Color.colorToHSV(color, hsv)
        hue = hsv[0]
    }
}

data class Waveform(
    val baseRadius: Float,
    val hue: Float,
    val saturation: Float,
    val lightness: Float,
    val gradientColors1: FloatArray,
    val gradientColors2: FloatArray,
    var rotation: Float
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as Waveform

        if (baseRadius != other.baseRadius) return false
        if (hue != other.hue) return false
        if (saturation != other.saturation) return false
        if (lightness != other.lightness) return false
        if (rotation != other.rotation) return false

        return true
    }

    override fun hashCode(): Int {
        var result = baseRadius.hashCode()
        result = 31 * result + hue.hashCode()
        result = 31 * result + saturation.hashCode()
        result = 31 * result + lightness.hashCode()
        result = 31 * result + rotation.hashCode()
        return result
    }
}

