package com.firstdraft.foundation

import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class AppNavigationTest {
    private fun entries(count: Int) = (1..count).map { ApplicationEntry("entry-$it", "Entry $it", "/items-$it", 0) }

    @Test fun oneThroughFiveEntriesRemainDirect() {
        (1..5).forEach {
            val values = entries(it)
            assertEquals(values, AppNavigation.visibleEntries(values))
            assertEquals(emptyList<ApplicationEntry>(), AppNavigation.overflowEntries(values))
        }
    }

    @Test fun moreKeepsEveryOverflowDestinationInAuthoredOrder() {
        val values = entries(9)
        val visible = AppNavigation.visibleEntries(values)
        assertEquals(values.take(4), visible.take(4))
        assertEquals(AppNavigation.MORE_ID, visible.last().id)
        assertEquals(values.drop(4), AppNavigation.overflowEntries(values))
    }

    @Test fun requiresAReachableRoot() {
        assertThrows(IllegalArgumentException::class.java) { AppNavigation.visibleEntries(emptyList()) }
    }
}
