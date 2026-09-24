package com.firstdraft.foundation

import java.net.URI
import java.net.URISyntaxException

object CodespacesPreview {
    private val codespaceHost = Regex("[a-z0-9-]+-[0-9]+\\.app\\.github\\.dev")

    fun headers(url: String, root: String, production: String, debug: Boolean): Map<String, String> {
        if (!debug || root == production) return emptyMap()
        val origin = uri(root) ?: return emptyMap()
        val request = uri(url) ?: return emptyMap()
        val matching = origin.scheme == "https" && request.scheme == "https" &&
            origin.host != null && codespaceHost.matches(origin.host) &&
            request.host == origin.host && port(request) == port(origin) &&
            origin.userInfo == null && request.userInfo == null
        return if (matching) mapOf("X-Tunnel-Skip-AntiPhishing-Page" to "true") else emptyMap()
    }

    private fun port(uri: URI): Int = if (uri.port == -1) 443 else uri.port

    private fun uri(value: String): URI? = try {
        URI(value)
    } catch (_: URISyntaxException) {
        null
    }
}
