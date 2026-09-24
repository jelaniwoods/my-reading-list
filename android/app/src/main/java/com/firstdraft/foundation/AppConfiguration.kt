package com.firstdraft.foundation

import android.content.Intent
import com.firstdraft.foundation.generated.GeneratedApplication

object AppConfiguration {
    var rootOrigin: String = GeneratedApplication.railsOrigin
        private set

    fun configure(intent: Intent?) {
        rootOrigin = PreviewOrigin.resolve(
            GeneratedApplication.railsOrigin,
            intent?.getStringExtra("APP_ROOT_URL"),
            BuildConfig.DEBUG
        )
    }
}
