# Keep Flutter internal classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.dynamic_feature.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep SQLite / Sqflite native methods if using local databases
-keep class com.tekartik.sqflite.** { *; }

# Ignore missing Play Store deferred component references in Flutter Engine
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Prevent R8 from complaining about missing classes
-ignorewarnings

# Prevent R8 from stripping Flutter engine & plugin reflection
-keep class io.flutter.** { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Protect SQLite / Sqflite native bridge
-keep class com.tekartik.sqflite.** { *; }
-keepclassmembers class com.tekartik.sqflite.** { *; }

# Protect path_provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Keep generic JNI interfaces
-keepclasseswithmembernames class * {
    native <methods>;
}