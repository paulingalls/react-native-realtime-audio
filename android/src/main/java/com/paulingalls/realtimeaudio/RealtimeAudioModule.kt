package com.paulingalls.realtimeaudio

import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class RealtimeAudioModule : Module() {
    override fun definition() = ModuleDefinition {
        Name("RealtimeAudio")

        AsyncFunction("checkAndRequestAudioPermissions") {
            val hasPermissions = checkAndRequestAudioPermissions()
            hasPermissions
        }

    }

    private fun checkAndRequestAudioPermissions(): Boolean {
        if (appContext.reactContext!!.checkSelfPermission(
                Manifest.permission.RECORD_AUDIO
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            val permissions = arrayOf(Manifest.permission.RECORD_AUDIO)
            ActivityCompat.requestPermissions(appContext.currentActivity!!, permissions, 0)
        } else {
            return true;
        }
        return appContext.reactContext!!.checkSelfPermission(
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
    }
}
