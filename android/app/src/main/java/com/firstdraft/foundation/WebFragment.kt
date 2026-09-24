package com.firstdraft.foundation

import android.os.Bundle
import android.view.View
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.updatePadding
import dev.hotwire.core.turbo.errors.VisitError
import dev.hotwire.navigation.destinations.HotwireDestinationDeepLink
import dev.hotwire.navigation.fragments.HotwireWebFragment

@HotwireDestinationDeepLink(uri = "hotwire://fragment/web")
class WebFragment : HotwireWebFragment() {
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        labelNavigationButton()
        if (isModal) {
            // Hotwire hides the tab bar in modals, so the fragment owns any remaining bottom inset.
            ViewCompat.setOnApplyWindowInsetsListener(view) { fragment, insets ->
                val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout())
                fragment.updatePadding(bottom = bars.bottom)
                insets.inset(0, 0, 0, bars.bottom)
            }
        }
    }

    override fun createErrorView(error: VisitError): View =
        pageLoadErrorView(layoutInflater, error) { refresh(displayProgress = true) }
}
