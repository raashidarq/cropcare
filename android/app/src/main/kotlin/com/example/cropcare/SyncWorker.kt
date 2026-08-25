package com.example.cropcare

import android.content.Context
import androidx.work.WorkerParameters
import com.google.gson.Gson
import es.antonborri.home_widget.WorkManagerFlutterPlugin

/**
 * SyncWorker is the Android WorkManager entry-point for the periodic outbox
 * flush. The actual sync logic runs in a **Dart background isolate** managed
 * by the `workmanager` Flutter plugin. This class is intentionally thin —
 * all it does is delegate to the plugin's built-in worker base class which
 * handles isolate spawning and callback dispatch.
 *
 * Registered in AndroidManifest.xml as a <service> so WorkManager can
 * instantiate it by class name.
 */
// Note: No Kotlin implementation needed here — the workmanager Flutter plugin
// provides its own WorkerFactory and registers it automatically via
// GeneratedPluginRegistrant. This file exists solely to document the
// registration and satisfy any IDE navigation requirements.
