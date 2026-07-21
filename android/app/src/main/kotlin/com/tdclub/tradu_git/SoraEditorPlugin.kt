package com.tdclub.tradu_git

import android.content.Context
import android.graphics.Color
import android.view.View
import android.util.Log
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
import io.github.rosemoe.sora.widget.schemes.EditorColorScheme

class SoraEditorPlugin : FlutterPlugin, MethodCallHandler {
    companion object {
        private const val TAG = "SoraEditorPlugin"
    }

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
                val scrollX = call.argument<Int>("scrollX") ?: 0
                val scrollY = call.argument<Int>("scrollY") ?: 0
                val cursorLine = call.argument<Int>("cursorLine") ?: 0
                val cursorColumn = call.argument<Int>("cursorColumn") ?: 0

                Log.d(TAG, "setText text.length=${text.length} scrollX=$scrollX scrollY=$scrollY cursorLine=$cursorLine cursorColumn=$cursorColumn")
                current?.setText(text)

                val applyState = {
                    try {
                        current?.setSelection(cursorLine, cursorColumn, false)
                        current?.getScroller()?.startScroll(scrollX, scrollY, 0, 0, 0)
                        current?.getScroller()?.computeScrollOffset()
                        current?.getScroller()?.setEditorOffsets()
                        current?.invalidate()
                    } catch (e: Exception) {
                        Log.e(TAG, "applyState error: ${e.message}", e)
                    }
                }

                val h = current?.height ?: 0
                if (h > 0) {
                    applyState()
                } else {
                    current?.addOnLayoutChangeListener(object : View.OnLayoutChangeListener {
                        override fun onLayoutChange(
                            v: View?, left: Int, top: Int, right: Int, bottom: Int,
                            oldLeft: Int, oldTop: Int, oldRight: Int, oldBottom: Int
                        ) {
                            val newHeight = bottom - top
                            if (newHeight > 0) {
                                current?.removeOnLayoutChangeListener(this)
                                applyState()
                            }
                        }
                    })
                }
                result.success(null)
            }
            "getEditorState" -> {
                if (current != null) {
                    val cursor = current.cursor
                    val scrollX = current.offsetX
                    val scrollY = current.offsetY
                    val cursorLine = cursor.leftLine
                    val cursorColumn = cursor.leftColumn
                    Log.d(TAG, "getEditorState: scrollX=$scrollX scrollY=$scrollY cursorLine=$cursorLine cursorColumn=$cursorColumn")
                    val stateMap = mapOf(
                        "scrollX" to scrollX,
                        "scrollY" to scrollY,
                        "cursorLine" to cursorLine,
                        "cursorColumn" to cursorColumn
                    )
                    result.success(stateMap)
                } else {
                    Log.d(TAG, "getEditorState: current editor is null")
                    result.success(null)
                }
            }
            "search" -> {
                val query = call.argument<String>("query")
                if (query != null) {
                    try {
                        val searcher = current?.getSearcher()
                        if (searcher != null) {
                            if (query.isEmpty()) {
                                searcher.stopSearch()
                            } else {
                                val options = io.github.rosemoe.sora.widget.EditorSearcher.SearchOptions(
                                    io.github.rosemoe.sora.widget.EditorSearcher.SearchOptions.TYPE_NORMAL,
                                    true // caseInsensitive
                                )
                                searcher.search(query, options)
                            }
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        result.error("SEARCH_FAILED", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "Query is null", null)
                }
            }
            "findNext" -> {
                try {
                    val searcher = current?.getSearcher()
                    if (searcher != null) {
                        searcher.gotoNext()
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                } catch (e: Exception) {
                    result.error("FIND_NEXT_FAILED", e.message, null)
                }
            }
            "findPrevious" -> {
                try {
                    val searcher = current?.getSearcher()
                    if (searcher != null) {
                        searcher.gotoPrevious()
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                } catch (e: Exception) {
                    result.error("FIND_PREV_FAILED", e.message, null)
                }
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
                    "amoled" -> {
                        val amoledScheme = SchemeDarcula()
                        amoledScheme.setColor(EditorColorScheme.WHOLE_BACKGROUND, Color.BLACK)
                        amoledScheme.setColor(EditorColorScheme.LINE_NUMBER_BACKGROUND, Color.BLACK)
                        amoledScheme
                    }
                    else -> SchemeDarcula()
                }
                current?.colorScheme = scheme
                result.success(null)
            }
            "requestFocus" -> {
                current?.requestFocus()
                result.success(null)
            }
            "clearFocus" -> {
                current?.clearFocus()
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
        setTextSize(18f)
        isWordwrap = false
        isLineNumberEnabled = true
        isEditable = true
        colorScheme = SchemeDarcula()
    }
    private val channel = MethodChannel(messenger, "sora_editor")

    init {
        onEditorReady(editor)
        editor.setOnFocusChangeListener { _, hasFocus ->
            if (hasFocus) {
                channel.invokeMethod("onFocusGained", null)
            } else {
                channel.invokeMethod("onFocusLost", null)
            }
        }
    }

    override fun getView(): View = editor

    override fun dispose() {
        editor.release()
    }
}
