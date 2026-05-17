package co.vslbridge

import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer

/**
 * Flutter plugin wrapper around MediaPipe Tasks PoseLandmarker + HandLandmarker.
 *
 * The Dart API keeps the existing "holistic" channel names so the mobile app
 * does not need a broader refactor. This implementation emits 33 pose landmarks
 * plus left/right hand landmarks in MediaPipe order.
 */
class MediaPipeHolisticPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {
    private val tag = "MediaPipeHolisticPlugin"

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var applicationContext: Context? = null
    private var handLandmarker: HandLandmarker? = null
    private var poseLandmarker: PoseLandmarker? = null

    private var minDetectionConfidence = 0.5f
    private var minTrackingConfidence = 0.5f
    private var isRunning = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(
            binding.binaryMessenger,
            "co.vslbridge/mediapipe_holistic/method",
        )
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(
            binding.binaryMessenger,
            "co.vslbridge/mediapipe_holistic/event",
        )
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        applicationContext = binding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                val options = call.argument<Map<String, Any>>("options") ?: emptyMap()
                minDetectionConfidence =
                    (options["minDetectionConfidence"] as? Number)?.toFloat() ?: 0.5f
                minTrackingConfidence =
                    (options["minTrackingConfidence"] as? Number)?.toFloat() ?: 0.5f
                val poseReady = initializePoseLandmarker()
                val handReady = initializeHandLandmarker()
                if (poseReady && handReady) {
                    result.success(true)
                } else {
                    result.error(
                        "MEDIAPIPE_INIT_FAILED",
                        "Failed to initialize MediaPipe pose/hand landmarkers",
                        null,
                    )
                }
            }

            "start" -> {
                isRunning = true
                result.success(true)
            }

            "stop" -> {
                isRunning = false
                result.success(true)
            }

            "processImage" -> {
                val imageData = call.argument<ByteArray>("imageData")
                val width = call.argument<Int>("width") ?: 0
                val height = call.argument<Int>("height") ?: 0
                val timestamp = call.argument<Long>("timestamp") ?: System.currentTimeMillis()

                if (imageData != null && width > 0 && height > 0) {
                    processImageData(imageData, width, height, timestamp)
                }
                result.success(null)
            }

            "close" -> {
                close()
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    private fun initializeHandLandmarker(): Boolean {
        val context = applicationContext
        if (context == null) {
            Log.e(tag, "Cannot initialize hand landmarker: context is null")
            return false
        }

        try {
            val baseOptions = BaseOptions.builder()
                .setModelAssetPath("hand_landmarker.task")
                .build()

            val options = HandLandmarker.HandLandmarkerOptions.builder()
                .setBaseOptions(baseOptions)
                .setRunningMode(RunningMode.IMAGE)
                .setNumHands(2)
                .setMinHandDetectionConfidence(minDetectionConfidence)
                .setMinHandPresenceConfidence(minDetectionConfidence)
                .setMinTrackingConfidence(minTrackingConfidence)
                .build()

            handLandmarker?.close()
            handLandmarker = HandLandmarker.createFromOptions(context, options)
            Log.i(tag, "MediaPipe HandLandmarker initialized")
            return true
        } catch (e: Exception) {
            Log.e(tag, "Failed to initialize HandLandmarker: ${e.message}", e)
            return false
        }
    }

    private fun initializePoseLandmarker(): Boolean {
        val context = applicationContext
        if (context == null) {
            Log.e(tag, "Cannot initialize pose landmarker: context is null")
            return false
        }

        try {
            val baseOptions = BaseOptions.builder()
                .setModelAssetPath("pose_landmarker_lite.task")
                .build()

            val options = PoseLandmarker.PoseLandmarkerOptions.builder()
                .setBaseOptions(baseOptions)
                .setRunningMode(RunningMode.IMAGE)
                .setNumPoses(1)
                .setMinPoseDetectionConfidence(minDetectionConfidence)
                .setMinPosePresenceConfidence(minDetectionConfidence)
                .setMinTrackingConfidence(minTrackingConfidence)
                .build()

            poseLandmarker?.close()
            poseLandmarker = PoseLandmarker.createFromOptions(context, options)
            Log.i(tag, "MediaPipe PoseLandmarker initialized")
            return true
        } catch (e: Exception) {
            Log.e(tag, "Failed to initialize PoseLandmarker: ${e.message}", e)
            return false
        }
    }

    private fun processImageData(imageData: ByteArray, width: Int, height: Int, timestamp: Long) {
        val handDetector = handLandmarker
        val poseDetector = poseLandmarker
        if (!isRunning || handDetector == null || poseDetector == null) {
            return
        }

        try {
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            bitmap.copyPixelsFromBuffer(ByteBuffer.wrap(imageData))
            val mpImage = BitmapImageBuilder(bitmap).build()
            val poseResult = poseDetector.detect(mpImage)
            val handResult = handDetector.detect(mpImage)
            publishResult(poseResult, handResult, timestamp)
        } catch (e: Exception) {
            Log.e(tag, "Error processing image: ${e.message}", e)
        }
    }

    private fun publishResult(
        poseResult: PoseLandmarkerResult,
        handResult: HandLandmarkerResult,
        timestamp: Long,
    ) {
        val sink = eventSink ?: return
        val pose = poseResult.landmarks().firstOrNull()
        val hands = handResult.landmarks()
        if (pose == null && hands.isEmpty()) {
            return
        }

        val handednesses = handResult.handednesses()
        val payload = linkedMapOf<String, Any>("timestamp" to timestamp)

        if (pose != null) {
            payload["pose"] = mapOf(
                "landmarks" to pose.map { landmark ->
                    mapOf(
                        "x" to landmark.x(),
                        "y" to landmark.y(),
                        "z" to landmark.z(),
                        "visibility" to (landmark.visibility().orElse(1.0f)),
                    )
                },
            )
        }

        for (index in hands.indices) {
            val handedness = handednesses
                .getOrNull(index)
                ?.firstOrNull()
                ?.categoryName()
                ?: if (index == 0) "Left" else "Right"
            val key = if (handedness.equals("Left", ignoreCase = true)) "left" else "right"

            if (payload.containsKey(key)) {
                continue
            }

            val landmarks = hands[index].map { landmark ->
                mapOf(
                    "x" to landmark.x(),
                    "y" to landmark.y(),
                    "z" to landmark.z(),
                    "visibility" to 1.0f,
                )
            }

            payload[key] = mapOf(
                "handedness" to handedness,
                "landmarks" to landmarks,
            )
        }

        sink.success(payload)
    }

    private fun close() {
        isRunning = false
        poseLandmarker?.close()
        poseLandmarker = null
        handLandmarker?.close()
        handLandmarker = null
        eventSink = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        close()
        methodChannel.setMethodCallHandler(null)
        applicationContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) = Unit

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() = Unit
}
