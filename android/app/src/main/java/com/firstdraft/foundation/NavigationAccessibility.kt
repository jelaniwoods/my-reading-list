package com.firstdraft.foundation

import dev.hotwire.navigation.destinations.HotwireDestination

internal fun HotwireDestination.labelNavigationButton() {
    toolbarForNavigation()?.let { toolbar ->
        if (toolbar.navigationIcon != null) {
            toolbar.setNavigationContentDescription(
                if (isModal) R.string.foundation_navigation_close else R.string.foundation_navigation_back
            )
        }
    }
}
