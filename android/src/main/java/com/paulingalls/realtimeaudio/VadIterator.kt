package com.paulingalls.realtimeaudio

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import java.nio.FloatBuffer

class VadIterator constructor(
    modelPath: String,
    private val sampleRate: Long,
    frameSize: Long,
    private val threshold: Float,
    minSilenceDurationMs: Long
) {
    private val frameSize: Long
    private val minSilenceSamples: Long

    /** support 256 512 768 for 8k; 512 1024 1536 for 16k */
    private val windowSizeSamples: Long

    // model states
    private var triggerd: Boolean = false
    private var tempEnd: Long = 0
    private var currentSample: Long = 0

    // model inputs
    private var state: Array<Array<FloatArray>>

    init {
        val srPerMs = sampleRate / 1000;
        this.frameSize = frameSize;
        this.minSilenceSamples = srPerMs * minSilenceDurationMs;
        this.windowSizeSamples = frameSize * srPerMs;
        this.state = Array(2) { Array(1) { FloatArray(128) } }; // 64 -> 128

        initSession(modelPath);
    }

    private lateinit var env: OrtEnvironment;
    private lateinit var session: OrtSession;


    private fun initSession(modelPath: String) {
        env = OrtEnvironment.getEnvironment();
        val sessionOptions = OrtSession.SessionOptions();
        sessionOptions.setIntraOpNumThreads(1);
        sessionOptions.setInterOpNumThreads(1);
        sessionOptions.setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT);
        session = env.createSession(modelPath, sessionOptions);
    }

    fun resetState() {
        triggerd = false;
        tempEnd = 0;
        currentSample = 0;
        state = Array(2) { Array(1) { FloatArray(128) } };
    }


    fun predict(data: FloatArray): Boolean {
        val inputOrt =
            OnnxTensor.createTensor(env, FloatBuffer.wrap(data), longArrayOf(1, windowSizeSamples));
        val srOrt = OnnxTensor.createTensor(
            env, sampleRate
        );
        val stateOrt = OnnxTensor.createTensor(env, state); // Change hOrt and cOrt to stateOrt

        val outputOrt = session.run(
            mapOf(
                "input" to inputOrt,
                "sr" to srOrt,
                "state" to stateOrt, // Change h and c to state
            )
        );
        val output = (outputOrt[0].value as Array<FloatArray>
            ?: throw Exception("Unexpected output type"))[0][0];
        state = outputOrt[1].value as Array<Array<FloatArray>>; // Change hn and cn to state

        currentSample += windowSizeSamples;

        if (output >= threshold && tempEnd != 0.toLong()) {
            tempEnd = 0
        }

        if (output >= threshold && !triggerd) {
            triggerd = true
        }

        if (output < (threshold - 0.15) && triggerd) {
            if (tempEnd == 0.toLong()) {
                tempEnd = currentSample
            }

            if (currentSample - tempEnd >= minSilenceSamples) {
                triggerd = false
                tempEnd = 0
            }
        }
        return triggerd;
    }
}