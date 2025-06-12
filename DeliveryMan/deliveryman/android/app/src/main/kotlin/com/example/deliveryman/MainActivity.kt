package com.example.deliveryman

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.phone"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "dial") {
                val number = call.argument<String>("number")
                if (number != null) {
                    dialNumber(number)
                    result.success("Dialing $number")
                } else {
                    result.error("INVALID_ARGUMENT", "Phone number is required", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun dialNumber(phoneNumber: String) {
        try {
            val intent = Intent(Intent.ACTION_DIAL)
            intent.data = Uri.parse("tel:$phoneNumber")
            startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}