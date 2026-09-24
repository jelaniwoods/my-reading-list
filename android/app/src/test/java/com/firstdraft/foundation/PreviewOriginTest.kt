package com.firstdraft.foundation

import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class PreviewOriginTest {
    private val production = "https://example.com"

    @Test fun malformedGeneratedOriginsNameTheGeneratedSeam() {
        listOf("http://example.com", "https://example.com/tenant", "not a URL").forEach {
            val error = org.junit.Assert.assertThrows(IllegalArgumentException::class.java) {
                PreviewOrigin.resolve(it, "https://preview.example", false)
            }
            org.junit.Assert.assertTrue(error.message!!.startsWith("Generated Rails origin"))
        }
    }

    @Test fun releaseIgnoresEveryLaunchOverride() {
        listOf("http://localhost:3000", "https://other.example", "not a URL").forEach {
            assertEquals(production, PreviewOrigin.resolve(production, it, false))
        }
    }

    @Test fun debugAcceptsHttpsAndLocalDevelopmentOrigins() {
        listOf("https://sample-3000.app.github.dev", "http://127.0.0.1:3000", "http://localhost:3000",
            "http://[::1]:3000", "http://10.0.2.2:3000").forEach {
            assertEquals(it, PreviewOrigin.resolve(production, "$it/", true))
        }
    }

    @Test fun debugRejectsNonOriginsAndRemoteCleartext() {
        listOf("http://example.com", "https://user:password@example.com", "https://example.com/path",
            "https://example.com?query=yes", "https://example.com#fragment", "not a URL", "file:///tmp/app").forEach {
            assertThrows(IllegalArgumentException::class.java) { PreviewOrigin.resolve(production, it, true) }
        }
    }
}
