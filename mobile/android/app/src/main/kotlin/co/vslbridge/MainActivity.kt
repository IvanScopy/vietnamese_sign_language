package co.vslbridge

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import co.vslbridge.MediaPipeHolisticPlugin

/**
 * Main Activity for VSL Bridge mobile app.
 *
 * Configures Flutter engine and registers platform-specific plugins:
 * - MediaPipeHolisticPlugin: Native Android holistic landmark detection
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Register the MediaPipe Holistic plugin with the Flutter engine
        flutterEngine.plugins.add(MediaPipeHolisticPlugin())
    }
}
