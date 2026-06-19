package com.tdclub.tradu_git

import android.database.Cursor
import android.database.MatrixCursor
import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import android.provider.DocumentsContract
import android.provider.DocumentsProvider
import java.io.File
import java.io.FileNotFoundException
import java.io.IOException

class TraduGitDocumentsProvider : DocumentsProvider() {

    private val DEFAULT_ROOT_PROJECTION: Array<String> = arrayOf(
        DocumentsContract.Root.COLUMN_ROOT_ID,
        DocumentsContract.Root.COLUMN_FLAGS,
        DocumentsContract.Root.COLUMN_TITLE,
        DocumentsContract.Root.COLUMN_DOCUMENT_ID,
        DocumentsContract.Root.COLUMN_ICON
    )

    private val DEFAULT_DOCUMENT_PROJECTION: Array<String> = arrayOf(
        DocumentsContract.Document.COLUMN_DOCUMENT_ID,
        DocumentsContract.Document.COLUMN_MIME_TYPE,
        DocumentsContract.Document.COLUMN_DISPLAY_NAME,
        DocumentsContract.Document.COLUMN_LAST_MODIFIED,
        DocumentsContract.Document.COLUMN_FLAGS,
        DocumentsContract.Document.COLUMN_SIZE
    )

    override fun onCreate(): Boolean {
        val reposDir = File(context?.filesDir, "repos")
        if (!reposDir.exists()) {
            reposDir.mkdirs()
        }
        return true
    }

    override fun queryRoots(projection: Array<String>?): Cursor {
        val flags = DocumentsContract.Root.FLAG_SUPPORTS_CREATE or
                DocumentsContract.Root.FLAG_SUPPORTS_IS_CHILD

        val result = MatrixCursor(projection ?: DEFAULT_ROOT_PROJECTION)
        val row = result.newRow()
        row.add(DocumentsContract.Root.COLUMN_ROOT_ID, "tradu_git_root")
        row.add(DocumentsContract.Root.COLUMN_FLAGS, flags)
        row.add(DocumentsContract.Root.COLUMN_TITLE, "Tradu-Git")
        
        val reposDir = File(context?.filesDir, "repos")
        row.add(DocumentsContract.Root.COLUMN_DOCUMENT_ID, reposDir.absolutePath)
        row.add(DocumentsContract.Root.COLUMN_ICON, R.mipmap.ic_launcher)
        return result
    }

    override fun queryDocument(documentId: String?, projection: Array<String>?): Cursor {
        val result = MatrixCursor(projection ?: DEFAULT_DOCUMENT_PROJECTION)
        val file = getFileForDocId(documentId)
        addFileRow(result, file)
        return result
    }

    override fun queryChildDocuments(
        parentDocumentId: String?,
        projection: Array<String>?,
        sortOrder: String?
    ): Cursor {
        val result = MatrixCursor(projection ?: DEFAULT_DOCUMENT_PROJECTION)
        val parent = getFileForDocId(parentDocumentId)
        val files = parent.listFiles() ?: return result
        for (file in files) {
            addFileRow(result, file)
        }
        return result
    }

    override fun openDocument(
        documentId: String?,
        mode: String,
        signal: CancellationSignal?
    ): ParcelFileDescriptor {
        val file = getFileForDocId(documentId)
        val accessMode = ParcelFileDescriptor.parseMode(mode)
        return ParcelFileDescriptor.open(file, accessMode)
    }

    override fun createDocument(
        parentDocumentId: String?,
        mimeType: String?,
        displayName: String?
    ): String {
        val parent = getFileForDocId(parentDocumentId)
        val child = File(parent, displayName ?: "unnamed").canonicalFile
        if (!child.path.startsWith(parent.canonicalPath)) {
            throw SecurityException("Access denied: path traversal detected")
        }
        if (mimeType == DocumentsContract.Document.MIME_TYPE_DIR) {
            child.mkdirs()
        } else {
            child.createNewFile()
        }
        return child.absolutePath
    }

    override fun deleteDocument(documentId: String?) {
        val file = getFileForDocId(documentId)
        val reposDir = File(context?.filesDir, "repos").canonicalFile
        if (file == reposDir) {
            throw SecurityException("Cannot delete the root repos directory")
        }
        file.deleteRecursively()
    }

    override fun renameDocument(documentId: String?, displayName: String?): String {
        val file = getFileForDocId(documentId)
        val reposDir = File(context?.filesDir, "repos").canonicalFile
        if (file == reposDir) {
            throw SecurityException("Cannot rename the root repos directory")
        }
        val dest = File(file.parentFile, displayName ?: "unnamed").canonicalFile
        if (!dest.path.startsWith(reposDir.canonicalPath)) {
            throw SecurityException("Access denied: path traversal detected")
        }
        if (file.renameTo(dest)) {
            return dest.absolutePath
        } else {
            throw IOException("Failed to rename document to $displayName")
        }
    }

    private fun getFileForDocId(documentId: String?): File {
        if (documentId == null) {
            throw FileNotFoundException("Document ID is null")
        }
        val reposDir = File(context?.filesDir, "repos").canonicalFile
        val file = File(documentId).canonicalFile
        if (!file.path.startsWith(reposDir.canonicalPath)) {
            throw SecurityException("Access to path outside sandbox repos is denied: ${file.path}")
        }
        return file
    }

    private fun addFileRow(result: MatrixCursor, file: File) {
        val row = result.newRow()
        row.add(DocumentsContract.Document.COLUMN_DOCUMENT_ID, file.absolutePath)
        row.add(DocumentsContract.Document.COLUMN_DISPLAY_NAME, file.name)
        row.add(DocumentsContract.Document.COLUMN_LAST_MODIFIED, file.lastModified())
        row.add(DocumentsContract.Document.COLUMN_SIZE, file.length())

        var flags = DocumentsContract.Document.FLAG_SUPPORTS_DELETE or
                DocumentsContract.Document.FLAG_SUPPORTS_RENAME

        if (file.isDirectory) {
            row.add(DocumentsContract.Document.COLUMN_MIME_TYPE, DocumentsContract.Document.MIME_TYPE_DIR)
            flags = flags or DocumentsContract.Document.FLAG_DIR_SUPPORTS_CREATE
        } else {
            row.add(DocumentsContract.Document.COLUMN_MIME_TYPE, getMimeType(file))
            flags = flags or DocumentsContract.Document.FLAG_SUPPORTS_WRITE
        }
        row.add(DocumentsContract.Document.COLUMN_FLAGS, flags)
    }

    private fun getMimeType(file: File): String {
        val ext = file.extension.lowercase()
        return when (ext) {
            "txt", "md", "json", "yaml", "yml", "xml", "csv", "rpy", "py" -> "text/plain"
            "html", "htm" -> "text/html"
            "css" -> "text/css"
            "js" -> "application/javascript"
            "ts" -> "application/typescript"
            "kt" -> "text/x-kotlin"
            "java" -> "text/x-java-source"
            "dart" -> "text/x-dart"
            "rs" -> "text/x-rust"
            "sh" -> "application/x-sh"
            "png" -> "image/png"
            "jpg", "jpeg" -> "image/jpeg"
            "gif" -> "image/gif"
            else -> "application/octet-stream"
        }
    }
}
