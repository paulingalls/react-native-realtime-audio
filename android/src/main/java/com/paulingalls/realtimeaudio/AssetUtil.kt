package com.paulingalls.realtimeaudio

import android.content.Context
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

object AssetUtil {
    /**
     * Copies an asset file to the app's internal storage if it hasn't already been copied,
     * and returns its absolute file path.
     *
     * @param context       the application context
     * @param assetFileName the name of the asset file (e.g., "silero_vad_16k_op15.onnx")
     * @return the absolute path to the copied file, or null if the copy fails
     */
    fun getAssetFilePath(context: Context, assetFileName: String): String? {
        val file = File(context.filesDir, assetFileName)
        if (!file.exists()) {
            try {
                context.assets.open(assetFileName).use { inputStream ->
                    FileOutputStream(file).use { outputStream ->
                        val buffer = ByteArray(1024)
                        var length = inputStream.read(buffer)
                        while (length != -1) {
                            outputStream.write(buffer, 0, length)
                            length = inputStream.read(buffer)
                        }
                        outputStream.flush()
                    }
                }
            } catch (e: IOException) {
                e.printStackTrace()
                return null
            }
        }
        return file.absolutePath
    }
}
