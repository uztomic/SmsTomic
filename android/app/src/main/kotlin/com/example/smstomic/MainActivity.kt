package com.example.smstomic

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val smsChannelName = "com.tomicsms/sms"
    private val fileChannelName = "com.tomicsms/files"
    private val pickCsvRequestCode = 4201
    private val saveCsvRequestCode = 4202

    private var pendingFileResult: MethodChannel.Result? = null
    private var pendingSaveBytes: ByteArray? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, smsChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sendSms" -> {
                        val phone = call.argument<String>("phone")
                        val message = call.argument<String>("message")
                        val subscriptionId = call.argument<Int>("subscriptionId")
                        if (phone.isNullOrBlank() || message.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "phone yoki message bo'sh", null)
                            return@setMethodCallHandler
                        }
                        try {
                            sendSms(phone, message, subscriptionId)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SEND_FAILED", e.message, null)
                        }
                    }
                    "getSimList" -> {
                        try {
                            result.success(getSimSubscriptions())
                        } catch (e: Exception) {
                            result.error("SIM_LIST_FAILED", e.message, null)
                        }
                    }
                    "startSendProgress" -> {
                        val total = call.argument<Int>("total") ?: 0
                        sendProgressToService(sent = 0, total = total, done = false)
                        result.success(true)
                    }
                    "updateSendProgress" -> {
                        val sent = call.argument<Int>("sent") ?: 0
                        val total = call.argument<Int>("total") ?: 0
                        sendProgressToService(sent = sent, total = total, done = false)
                        result.success(true)
                    }
                    "completeSendProgress" -> {
                        val sent = call.argument<Int>("sent") ?: 0
                        val total = call.argument<Int>("total") ?: 0
                        sendProgressToService(sent = sent, total = total, done = true)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, fileChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickCsv" -> {
                        if (pendingFileResult != null) {
                            result.error("BUSY", "Fayl bilan ish allaqachon davom etmoqda", null)
                            return@setMethodCallHandler
                        }
                        pendingFileResult = result
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "*/*"
                        }
                        startActivityForResult(intent, pickCsvRequestCode)
                    }
                    "saveCsv" -> {
                        if (pendingFileResult != null) {
                            result.error("BUSY", "Fayl bilan ish allaqachon davom etmoqda", null)
                            return@setMethodCallHandler
                        }
                        val filename = call.argument<String>("filename") ?: "export.csv"
                        val bytes = call.argument<ByteArray>("bytes")
                        if (bytes == null) {
                            result.error("INVALID_ARGS", "bytes bo'sh", null)
                            return@setMethodCallHandler
                        }
                        pendingFileResult = result
                        pendingSaveBytes = bytes
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "text/csv"
                            putExtra(Intent.EXTRA_TITLE, filename)
                        }
                        startActivityForResult(intent, saveCsvRequestCode)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            pickCsvRequestCode -> handlePickResult(resultCode, data)
            saveCsvRequestCode -> handleSaveResult(resultCode, data)
        }
    }

    private fun handlePickResult(resultCode: Int, data: Intent?) {
        val result = pendingFileResult
        pendingFileResult = null

        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result?.success(null)
            return
        }

        val uri: Uri = data.data!!
        try {
            val bytes = contentResolver.openInputStream(uri)?.use { input ->
                val buffer = ByteArrayOutputStream()
                input.copyTo(buffer)
                buffer.toByteArray()
            }
            result?.success(bytes)
        } catch (e: Exception) {
            result?.error("READ_FAILED", e.message, null)
        }
    }

    private fun handleSaveResult(resultCode: Int, data: Intent?) {
        val result = pendingFileResult
        pendingFileResult = null
        val bytes = pendingSaveBytes
        pendingSaveBytes = null

        if (resultCode != Activity.RESULT_OK || data?.data == null || bytes == null) {
            result?.success(false)
            return
        }

        try {
            contentResolver.openOutputStream(data.data!!)?.use { it.write(bytes) }
            result?.success(true)
        } catch (e: Exception) {
            result?.error("WRITE_FAILED", e.message, null)
        }
    }

    /// Qurilmadagi faol SIM kartalar ro'yxatini qaytaradi. READ_PHONE_STATE
    /// ruxsati berilmagan bo'lsa, bo'sh ro'yxat qaytadi (Dart tomon
    /// avval ruxsat so'raydi).
    private fun getSimSubscriptions(): List<Map<String, Any?>> {
        val list = mutableListOf<Map<String, Any?>>()
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE)
            != PackageManager.PERMISSION_GRANTED
        ) {
            return list
        }
        val subscriptionManager = getSystemService(SubscriptionManager::class.java)
        val subscriptions = subscriptionManager?.activeSubscriptionInfoList ?: return list
        for (info in subscriptions) {
            list.add(
                mapOf(
                    "subscriptionId" to info.subscriptionId,
                    "slotIndex" to info.simSlotIndex,
                    "displayName" to (info.displayName?.toString() ?: "SIM ${info.simSlotIndex + 1}"),
                    "carrierName" to (info.carrierName?.toString() ?: ""),
                )
            )
        }
        return list
    }

    /// SmsSendingService'ga joriy progressni yuboradi — servis shu
    /// ma'lumot bilan doimiy bildirishnomani yangilaydi.
    private fun sendProgressToService(sent: Int, total: Int, done: Boolean) {
        val intent = Intent(this, SmsSendingService::class.java).apply {
            putExtra(SmsSendingService.EXTRA_SENT, sent)
            putExtra(SmsSendingService.EXTRA_TOTAL, total)
            putExtra(SmsSendingService.EXTRA_DONE, done)
        }
        ContextCompat.startForegroundService(this, intent)
    }

    private fun sendSms(phone: String, message: String, subscriptionId: Int?) {
        val smsManager: SmsManager =
            if (subscriptionId != null && subscriptionId >= 0) {
                SmsManager.getSmsManagerForSubscriptionId(subscriptionId)
            } else {
                SmsManager.getDefault()
            }
        if (message.length > 160) {
            val parts = smsManager.divideMessage(message)
            smsManager.sendMultipartTextMessage(phone, null, parts, null, null)
        } else {
            smsManager.sendTextMessage(phone, null, message, null, null)
        }
    }
}
