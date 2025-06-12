package com.example.artefacto_mobile_123220016

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.provider.Settings
import android.net.Uri
import android.os.Build
import android.app.AlarmManager
import android.content.Context
import android.os.PowerManager

class MainActivity : FlutterActivity() {
    private val CHANNEL = "android_settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openExactAlarmSettings" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                data = Uri.parse("package:$packageName")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to open settings: ${e.message}", null)
                    }
                }
                "canScheduleExactAlarms" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                            result.success(alarmManager.canScheduleExactAlarms())
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to check permission: ${e.message}", null)
                    }
                }
                "isIgnoringBatteryOptimizations" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                            result.success(powerManager.isIgnoringBatteryOptimizations(packageName))
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to check battery optimization: ${e.message}", null)
                    }
                }
                "requestIgnoreBatteryOptimizations" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            // Try direct request first
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = Uri.parse("package:$packageName")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            
                            // Check if intent can be resolved
                            if (intent.resolveActivity(packageManager) != null) {
                                startActivity(intent)
                                result.success(true)
                            } else {
                                // Fallback to general battery settings
                                val fallbackIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                }
                                startActivity(fallbackIntent)
                                result.success(true)
                            }
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        // Final fallback to app settings
                        try {
                            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.parse("package:$packageName")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (ex: Exception) {
                            result.error("ERROR", "Failed to open any settings: ${ex.message}", null)
                        }
                    }
                }
                "openBatteryOptimizationSettings" -> {
                    try {
                        // Try general battery optimization settings first
                        val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        
                        if (intent.resolveActivity(packageManager) != null) {
                            startActivity(intent)
                            result.success(true)
                        } else {
                            // Fallback to app settings
                            val fallbackIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.parse("package:$packageName")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(fallbackIntent)
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to open battery settings: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
