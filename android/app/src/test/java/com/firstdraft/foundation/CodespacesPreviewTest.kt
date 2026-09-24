package com.firstdraft.foundation

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class CodespacesPreviewTest {
    private val root = "https://sample-workspace-3000.app.github.dev"
    private val production = "https://example.com"

    @Test fun decoratesOnlyTheConfiguredDebugCodespaceOrigin() {
        assertEquals(mapOf("X-Tunnel-Skip-AntiPhishing-Page" to "true"),
            CodespacesPreview.headers("$root/items?page=2", root, production, true))
        assertTrue(CodespacesPreview.headers(root, root, production, false).isEmpty())
        assertTrue(CodespacesPreview.headers(root, root, root, true).isEmpty())
        listOf("https://other-3000.app.github.dev", "$root:444/items", "$root.evil.test/items",
            "http://sample-workspace-3000.app.github.dev", "https://user@sample-workspace-3000.app.github.dev",
            "malformed URL").forEach {
            assertTrue(it, CodespacesPreview.headers(it, root, production, true).isEmpty())
        }
    }

    @Test fun leavesOrdinaryHttpsOriginsAlone() {
        assertTrue(CodespacesPreview.headers("https://preview.example.com/items",
            "https://preview.example.com", production, true).isEmpty())
    }
}
