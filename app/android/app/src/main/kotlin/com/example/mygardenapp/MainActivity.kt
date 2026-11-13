package com.example.mygardenapp

import android.content.res.Configuration
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val launcherIcons by lazy { LauncherIcons(this) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mygarden/launcher_icon")
            .setMethodCallHandler { call, result ->
                if (call.method != "setTheme") {
                    result.notImplemented()
                } else {
                    val mode = call.argument<String>("theme")
                    if (mode !in listOf("light", "dark", "system")) {
                        result.error("invalid_theme", "Tema inválido", null)
                    } else {
                        try {
                            launcherIcons.setTheme(mode!!)
                            result.success(null)
                        } catch (error: Exception) {
                            Log.w("MyGarden", "Unable to update launcher icon", error)
                            result.error("launcher_icon_failed", "Não foi possível atualizar o ícone", null)
                        }
                    }
                }
            }
    }

    override fun onResume() {
        super.onResume()
        refreshLauncherIcon()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        refreshLauncherIcon()
    }

    private fun refreshLauncherIcon() {
        try {
            launcherIcons.refresh()
        } catch (error: Exception) {
            // A launcher failure must not prevent opening the garden.
            Log.w("MyGarden", "Unable to refresh launcher icon", error)
        }
    }
}
