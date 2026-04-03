package com.effortbf.ef_fort_bf

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// ════════════════════════════════════════════════════════════
// SECURITE : Bloquer les captures d'écran via FLAG_SECURE
// L'admin est exempté de ce blocage (géré côté Flutter)
// ════════════════════════════════════════════════════════════
class MainActivity : FlutterActivity() {
    private val CHANNEL = "ef_fort_bf/securite"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecureFlag" -> {
                        val secure = call.argument<Boolean>("secure") ?: true
                        if (secure) {
                            // Activer FLAG_SECURE — bloque screenshots et screen recording
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            // Désactiver FLAG_SECURE (pour l'admin)
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(secure)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
