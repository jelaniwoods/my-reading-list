package com.firstdraft.foundation

import android.annotation.SuppressLint
import android.view.LayoutInflater
import android.view.View
import android.widget.TextView
import dev.hotwire.core.turbo.errors.VisitError

@SuppressLint("InflateParams")
internal fun pageLoadErrorView(inflater: LayoutInflater, error: VisitError, retry: () -> Unit): View =
    inflater.inflate(R.layout.foundation_page_load_error, null).apply {
        findViewById<TextView>(R.id.foundation_error_description).text = error.description()
        findViewById<View>(R.id.foundation_retry).setOnClickListener { retry() }
    }
