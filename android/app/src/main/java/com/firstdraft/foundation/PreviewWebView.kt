package com.firstdraft.foundation

import android.content.Context
import androidx.core.content.ContextCompat
import com.firstdraft.foundation.generated.GeneratedApplication
import dev.hotwire.core.turbo.webview.HotwireWebView

class PreviewWebView(context: Context) : HotwireWebView(context) {
    init {
        setBackgroundColor(ContextCompat.getColor(context, R.color.foundation_background))
    }

    override fun loadUrl(url: String) {
        super.loadUrl(url, previewHeaders(url).toMutableMap())
    }

    override fun loadUrl(url: String, additionalHttpHeaders: MutableMap<String, String>) {
        super.loadUrl(url, (additionalHttpHeaders + previewHeaders(url)).toMutableMap())
    }

    private fun previewHeaders(url: String) = CodespacesPreview.headers(
        url, AppConfiguration.rootOrigin, GeneratedApplication.railsOrigin, BuildConfig.DEBUG
    )
}
