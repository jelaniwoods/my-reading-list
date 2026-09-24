package com.firstdraft.foundation

import android.os.Bundle
import android.view.View
import androidx.activity.enableEdgeToEdge
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.updatePadding
import com.firstdraft.foundation.generated.GeneratedApplication
import com.google.android.material.bottomnavigation.BottomNavigationView
import dev.hotwire.core.turbo.webview.WebViewInfo
import dev.hotwire.core.turbo.webview.WebViewVersionCompatibility
import dev.hotwire.navigation.activities.HotwireActivity
import dev.hotwire.navigation.navigator.NavigatorConfiguration
import dev.hotwire.navigation.tabs.HotwireBottomNavigationController
import dev.hotwire.navigation.tabs.HotwireBottomTab

class MainActivity : HotwireActivity() {
    private var selectedTab = 0
    private var bottomNavigationController: HotwireBottomNavigationController? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        AppConfiguration.configure(intent)
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        selectedTab = savedInstanceState?.getInt("selectedTab") ?: 0
        val view = findViewById<BottomNavigationView>(R.id.bottom_nav)
        val entries = AppNavigation.visibleEntries(GeneratedApplication.entries)
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.root)) { root, insets ->
            val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout())
            val keyboard = insets.getInsets(WindowInsetsCompat.Type.ime())
            // Hotwire's toolbar owns the top inset; Material tabs own the bottom inset when present.
            root.updatePadding(left = bars.left, right = bars.right,
                bottom = maxOf(keyboard.bottom, if (entries.size == 1) bars.bottom else 0))
            insets.inset(bars.left, 0, bars.right, root.paddingBottom)
        }
        if (entries.size == 1) {
            view.visibility = View.GONE
        } else {
            bottomNavigationController = HotwireBottomNavigationController(this, view, lazyLoadTabs = true).also {
                it.load(entries.mapIndexed { index, entry ->
                    HotwireBottomTab(entry.label, entry.iconResId, configuration = configuration(index, entry))
                }, selectedTab)
                it.setOnTabSelectedListener { index, _ -> selectedTab = index }
            }
        }
        WebViewVersionCompatibility.displayUpdateDialogIfOutdated(this, WebViewInfo.REQUIRED_WEBVIEW_VERSION)
    }

    override fun navigatorConfigurations() = AppNavigation.visibleEntries(GeneratedApplication.entries)
        .mapIndexed { index, entry -> configuration(index, entry) }

    override fun onSaveInstanceState(outState: Bundle) {
        outState.putInt("selectedTab", selectedTab)
        super.onSaveInstanceState(outState)
    }

    private fun configuration(index: Int, entry: ApplicationEntry) = NavigatorConfiguration(
        name = entry.id,
        startLocation = AppConfiguration.rootOrigin + entry.path,
        navigatorHostId = GeneratedApplication.hostIds[index]
    )
}
