package com.firstdraft.foundation

import java.net.URI
import java.net.URISyntaxException

object PreviewOrigin {
    private val localHosts = setOf("localhost", "127.0.0.1", "::1", "10.0.2.2")

    fun resolve(production: String, override: String?, debug: Boolean): String {
        val hasOverride = debug && !override.isNullOrBlank()
        val raw = if (hasOverride) override!! else production
        val source = if (hasOverride) "APP_ROOT_URL" else "Generated Rails origin"
        val uri = parse(raw, source)
        val host = uri.host?.removePrefix("[")?.removeSuffix("]")?.lowercase()
        val secure = uri.scheme == "https"
        val local = hasOverride && uri.scheme == "http" && host in localHosts
        require((secure || local) && !host.isNullOrEmpty() && uri.userInfo == null &&
            uri.rawQuery == null && uri.rawFragment == null && (uri.port == -1 || uri.port in 1..65535) &&
            (uri.rawPath.isNullOrEmpty() || uri.rawPath == "/")) {
            "$source must be an HTTPS origin${if (hasOverride) " or a Debug local-development HTTP origin" else ""}"
        }
        return raw.removeSuffix("/")
    }

    private fun parse(raw: String, source: String): URI = try {
        URI(raw)
    } catch (error: URISyntaxException) {
        throw IllegalArgumentException("$source is not a valid URL", error)
    }
}
