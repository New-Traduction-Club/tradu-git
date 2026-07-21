package com.tdclub.tradu_git

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.DocumentsContract
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
    }

    private val STORAGE_CHANNEL = "com.tdclub.tradu_git/storage"
    private val BROWSER_CHANNEL = "com.tdclub.tradu_git/browser"
    private val OAUTH_CHANNEL = "com.tdclub.tradu_git/oauth"

    private var oauthChannel: MethodChannel? = null
    private var initialLink: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val action = intent?.action
        val data: Uri? = intent?.data
        if (Intent.ACTION_VIEW == action && data != null) {
            val url = data.toString()
            if (url.startsWith("tradu-git://oauth")) {
                Log.d(TAG, "Intercepted OAuth Redirect: $url")
                val channel = oauthChannel
                if (channel != null) {
                    channel.invokeMethod("onOAuthCallback", url)
                } else {
                    initialLink = url
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(SoraEditorPlugin())

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInternalStoragePath" -> {
                    result.success(context.filesDir.absolutePath)
                }
                "openDocumentsProvider" -> {
                    try {
                        val rootUri = DocumentsContract.buildRootUri("com.tdclub.tradu_git.documents", "tradu_git_root")
                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(rootUri, "vnd.android.document/root")
                            addCategory(Intent.CATEGORY_DEFAULT)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        context.startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error opening documents provider: ${e.message}", e)
                        result.error("OPEN_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BROWSER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchBrowser" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            context.startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("LAUNCH_FAILED", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "URL is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        oauthChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OAUTH_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialLink" -> {
                        val link = initialLink
                        initialLink = null
                        result.success(link)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }
}
