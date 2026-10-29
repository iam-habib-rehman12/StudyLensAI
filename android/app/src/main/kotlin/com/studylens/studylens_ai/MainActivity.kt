package com.studylens.studylens_ai

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL = "studylens/document_picker"
        const val PICK_PDF_REQUEST = 4102
        const val MAX_PDF_BYTES = 14 * 1024 * 1024
    }

    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "selectPdf") {
                    result.notImplemented()
                } else if (pendingResult != null) {
                    result.error("picker_busy", "The document picker is already open.", null)
                } else {
                    pendingResult = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "application/pdf"
                    }
                    startActivityForResult(intent, PICK_PDF_REQUEST)
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_PDF_REQUEST) return
        val result = pendingResult ?: return
        pendingResult = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        try {
            result.success(readDocument(uri))
        } catch (error: DocumentTooLargeException) {
            result.error("too_large", "The selected PDF exceeds 14 MB.", null)
        } catch (error: Exception) {
            result.error("read_failed", "The selected PDF could not be read.", null)
        }
    }

    private fun readDocument(uri: Uri): Map<String, Any> {
        val name = queryDisplayName(uri) ?: "study-document.pdf"
        val output = ByteArrayOutputStream()
        contentResolver.openInputStream(uri).use { input ->
            requireNotNull(input) { "Document stream is unavailable." }
            val buffer = ByteArray(8192)
            var total = 0
            while (true) {
                val count = input.read(buffer)
                if (count < 0) break
                total += count
                if (total > MAX_PDF_BYTES) throw DocumentTooLargeException()
                output.write(buffer, 0, count)
            }
        }
        return mapOf("name" to name, "bytes" to output.toByteArray())
    }

    private fun queryDisplayName(uri: Uri): String? =
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (!cursor.moveToFirst()) return@use null
                val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (index < 0) null else cursor.getString(index)
            }

    private class DocumentTooLargeException : Exception()
}
