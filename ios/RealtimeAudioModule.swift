import ExpoModulesCore

public class RealtimeAudioModule: Module {
  // Each module class must implement the definition function. The definition consists of components
  // that describes the module's functionality and behavior.
  // See https://docs.expo.dev/modules/module-api for more details about available components.
  public func definition() -> ModuleDefinition {
    // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
    // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
    // The module will be accessible from `requireNativeModule('RealtimeAudio')` in JavaScript.
    Name("RealtimeAudio")

    // Sets constant properties on the module. Can take a dictionary or a closure that returns a dictionary.
    Constants([
      "PI": Double.pi
    ])

    // Defines event names that the module can send to JavaScript.
    Events("onPlaybackStarted", "onPlaybackStopped")

    // Defines a JavaScript synchronous function that runs the native code on the JavaScript thread.
    Function("hello") {
      return "Hello world! 👋"
    }

    // Defines a JavaScript function that always returns a Promise and whose native code
    // is by default dispatched on the different thread than the JavaScript runtime runs on.
    AsyncFunction("setValueAsync") { (value: String) in
      // Send an event to JavaScript.
      self.sendEvent("onChange", [
        "value": value
      ])
    }

    // Enables the module to be used as a native view. Definition components that are accepted as part of the
    // view definition: Prop, Events.
    View(RealtimeAudioView.self) {
        Events("onPlaybackStart", "onPlaybackStop")

        // Props
        Prop("waveformColor") { (view: RealtimeAudioView, hexColor: String) in
            view.setWaveformColor(hexColor)
        }

        // Functions
        AsyncFunction("setAudioFormat") { (view: RealtimeAudioView, sampleRate: Double, bitsPerSample: Int, channels: UInt32) in
            view.setAudioFormat(sampleRate: sampleRate, bitsPerSample: bitsPerSample, channels: channels)
        }

        AsyncFunction("addBuffer") { (view: RealtimeAudioView, base64String: String) in
            view.addBuffer(base64String)
        }

        AsyncFunction("play") { (view: RealtimeAudioView) in
            view.play()
        }

        AsyncFunction("pause") { (view: RealtimeAudioView) in
            view.pause()
        }

        AsyncFunction("stop") { (view: RealtimeAudioView) in
            view.stop()
        }
    }
  }
}
