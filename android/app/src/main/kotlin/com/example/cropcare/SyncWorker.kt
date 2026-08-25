package com.example.cropcare

/**
 * SyncWorker is the Android WorkManager entry-point for the periodic outbox
 * flush. The actual sync logic runs in a **Dart background isolate** managed
 * by the `workmanager` Flutter plugin. This class is intentionally thin —
 * all it does is delegate to the plugin's built-in worker base class which
 * handles isolate spawning and callback dispatch.
 *
 * The `workmanager` plugin registers its own WorkerFactory automatically via
 * GeneratedPluginRegistrant, so no Kotlin implementation is needed here.
 * This file exists solely for documentation and IDE navigation purposes.
 */
