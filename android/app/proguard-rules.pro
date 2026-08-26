# Flutter and AndroidX Startup / WorkManager Proguard Rules

# Keep AndroidX WorkManager and Room database implementation reflection
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.work.Worker { *; }
-keep class * extends androidx.work.ListenableWorker { *; }
-keep class androidx.startup.** { *; }
-keep class androidx.room.** { *; }

# WorkManager Flutter Plugin
-keep class be.tramckrijte.workmanager.** { *; }

# TensorFlow Lite native bindings
-keep class org.tensorflow.lite.** { *; }
-keep class com.google.android.gms.tflite.** { *; }

# SQLite3 Flutter Libs
-keep class org.sqlite.** { *; }
