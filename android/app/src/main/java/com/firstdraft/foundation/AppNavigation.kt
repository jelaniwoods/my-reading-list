package com.firstdraft.foundation

object AppNavigation {
    const val MORE_PATH = "/__firstdraft_android_more__"
    const val MORE_ID = "firstdraft-more"

    fun visibleEntries(entries: List<ApplicationEntry>): List<ApplicationEntry> {
        require(entries.isNotEmpty()) { "Android navigation requires at least one entry" }
        return if (entries.size <= 5) entries else entries.take(4) + ApplicationEntry(
            MORE_ID, "More", MORE_PATH, R.drawable.foundation_icon_list
        )
    }

    fun overflowEntries(entries: List<ApplicationEntry>): List<ApplicationEntry> =
        if (entries.size > 5) entries.drop(4) else emptyList()
}
