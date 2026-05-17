# MediaPipe Holistic ProGuard rules
# Keep MediaPipe classes
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**

# Keep solution core
-keep class com.google.mediapipe.solutioncore.** { *; }
-dontwarn com.google.mediapipe.solutioncore.**

# Keep holistic specific classes
-keep class com.google.mediapipe.holistic.** { *; }
-dontwarn com.google.mediapipe.holistic.**

# Keep protobuf generated classes
-keep class com.google.mediapipe.formats.** { *; }
-dontwarn com.google.mediapipe.formats.**

# Keep JNI bindings
-keepclasseswithmembernames class * {
    native <methods>;
}

-keepclassmembers class * {
    native <methods>;
}
