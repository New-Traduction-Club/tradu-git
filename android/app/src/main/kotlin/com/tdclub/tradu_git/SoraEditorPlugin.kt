package com.tdclub.tradu_git

import android.content.Context
import android.view.View
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.StandardMessageCodec
import io.github.rosemoe.sora.widget.CodeEditor
import io.github.rosemoe.sora.widget.schemes.SchemeDarcula

class SoraEditorPlugin : FlutterPlugin, MethodCallHandler {
    private var channel: MethodChannel? = null
    private var editor: CodeEditor? = null

    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "sora_editor")
        channel?.setMethodCallHandler(this)
        binding.platformViewRegistry.registerViewFactory(
            "sora_editor_view",
            SoraEditorFactory(binding.binaryMessenger) { editor = it }
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        editor = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val current = editor
        when (call.method) {
            "setText" -> {
                val text = call.argument<String>("text") ?: ""
                current?.setText(text)
                result.success(null)
            }
            "getText" -> {
                result.success(current?.text?.toString() ?: "")
            }
            "setReadOnly" -> {
                val readOnly = call.argument<Boolean>("readOnly") ?: false
                current?.isEditable = !readOnly
                result.success(null)
            }
            "setWrap" -> {
                val wrap = call.argument<Boolean>("wrap") ?: true
                current?.isWordwrap = wrap
                result.success(null)
            }
            "setFontSize" -> {
                val size = call.argument<Double>("size")?.toFloat() ?: 12f
                current?.setTextSize(size)
                result.success(null)
            }
            "setLineNumbers" -> {
                val enabled = call.argument<Boolean>("enabled") ?: true
                current?.isLineNumberEnabled = enabled
                result.success(null)
            }
            "setTheme" -> {
                val themeName = call.argument<String>("themeName") ?: "darcula"
                val scheme = when (themeName) {
                    "darcula" -> SchemeDarcula()
                    else -> SchemeDarcula()
                }
                current?.colorScheme = scheme
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}

private class SoraEditorFactory(
    private val messenger: BinaryMessenger,
    private val onEditorReady: (CodeEditor) -> Unit,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return SoraEditorView(context, messenger, viewId, onEditorReady)
    }
}

private class SoraEditorView(
    context: Context,
    messenger: BinaryMessenger,
    id: Int,
    onEditorReady: (CodeEditor) -> Unit,
) : PlatformView {
    private val editor = CodeEditor(context).apply {
        setTextSize(12f)
        isWordwrap = true
        isLineNumberEnabled = true
        isEditable = true
        colorScheme = SchemeDarcula()
    }

    init {
        onEditorReady(editor)
    }

    override fun getView(): View = editor

    override fun dispose() {
        editor.release()
    }
}
