package com.firstdraft.foundation

import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.os.SystemClock
import android.widget.ImageButton
import androidx.annotation.StringRes
import androidx.core.view.children
import androidx.lifecycle.Lifecycle
import androidx.test.core.app.ActivityScenario
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import dev.hotwire.core.config.Hotwire
import dev.hotwire.core.turbo.config.PathConfiguration
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class NavigationAccessibilityTest {
    @Before fun loadNavigationFixture() {
        val assetsContext = object : ContextWrapper(InstrumentationRegistry.getInstrumentation().context) {
            override fun getApplicationContext(): Context = this
        }
        Hotwire.loadPathConfiguration(assetsContext,
            PathConfiguration.Location(assetFilePath = "json/navigation_accessibility.json"))
    }

    @After fun restoreApplicationConfiguration() {
        Hotwire.loadPathConfiguration(ApplicationProvider.getApplicationContext(),
            PathConfiguration.Location(assetFilePath = "json/android_v1.json"))
    }

    @Test fun aRootScreenDoesNotExposeABackControl() {
        launch().use { scenario ->
            awaitDestination(scenario)
            assertRootScreen(scenario, WebFragment::class.java)
        }
    }

    @Test fun pushedWebScreenLabelsItsBackControl() =
        assertNavigationControl("web", WebFragment::class.java, R.string.foundation_navigation_back)

    @Test fun fullScreenModalLabelsItsCloseControl() =
        assertNavigationControl("modal", WebFragment::class.java, R.string.foundation_navigation_close)

    @Test fun bottomSheetLabelsItsCloseControl() =
        assertNavigationControl("sheet", WebBottomSheetFragment::class.java, R.string.foundation_navigation_close)

    @Test fun nestedModalClosesTheCurrentScreenBeforeClosingThePreviousModal() {
        launch().use { scenario ->
            awaitDestination(scenario)
            lateinit var rootLocation: String
            scenario.onActivity { rootLocation = requireNotNull(it.delegate.currentNavigator?.location) }
            val firstModal = route(scenario, "/navigation-test/modal")
            route(scenario, "/navigation-test/modal/nested")
            clickNavigationControl(scenario, WebFragment::class.java, R.string.foundation_navigation_close)
            awaitDestination(scenario, firstModal)
            clickNavigationControl(scenario, WebFragment::class.java, R.string.foundation_navigation_close)
            awaitDestination(scenario, rootLocation)
            assertRootScreen(scenario, WebFragment::class.java)
        }
    }

    @Test fun moreRootHasNoBackControlAndOverflowReturnsToIt() {
        launch().use { scenario ->
            awaitDestination(scenario)
            val moreLocation = route(scenario, AppNavigation.MORE_PATH)
            assertRootScreen(scenario, MoreFragment::class.java)
            route(scenario, "/navigation-test/overflow")
            clickNavigationControl(scenario, WebFragment::class.java, R.string.foundation_navigation_back)
            awaitDestination(scenario, moreLocation)
            assertRootScreen(scenario, MoreFragment::class.java)
        }
    }

    private fun assertNavigationControl(path: String, fragmentClass: Class<*>, @StringRes labelRes: Int) {
        launch().use { scenario ->
            awaitDestination(scenario)
            lateinit var rootLocation: String
            scenario.onActivity { rootLocation = requireNotNull(it.delegate.currentNavigator?.location) }
            route(scenario, "/navigation-test/$path")
            clickNavigationControl(scenario, fragmentClass, labelRes)
            awaitDestination(scenario, rootLocation)
            assertRootScreen(scenario, WebFragment::class.java)
        }
    }

    private fun clickNavigationControl(scenario: ActivityScenario<MainActivity>, fragmentClass: Class<*>, @StringRes labelRes: Int) {
        scenario.onActivity { activity ->
            val destination = requireNotNull(activity.delegate.currentNavigator?.currentDestination)
            assertEquals(fragmentClass, destination.javaClass)
            val toolbar = requireNotNull(destination.toolbarForNavigation())
            assertNotNull(toolbar.navigationIcon)
            val button = toolbar.children.filterIsInstance<ImageButton>().single()
            assertEquals(activity.getString(labelRes), button.contentDescription?.toString())
            assertTrue(button.isClickable)
            button.performClick()
        }
    }

    private fun assertRootScreen(scenario: ActivityScenario<MainActivity>, fragmentClass: Class<*>) {
        scenario.onActivity { activity ->
            val navigator = requireNotNull(activity.delegate.currentNavigator)
            assertTrue(navigator.isAtStartDestination())
            val destination = requireNotNull(navigator.currentDestination)
            assertEquals(fragmentClass, destination.javaClass)
            val toolbar = requireNotNull(destination.toolbarForNavigation())
            assertNull(toolbar.navigationIcon)
            assertNull(toolbar.navigationContentDescription)
            assertTrue(toolbar.children.none { it is ImageButton })
        }
    }

    private fun route(scenario: ActivityScenario<MainActivity>, path: String): String {
        val location = "http://127.0.0.1:1$path"
        scenario.onActivity { requireNotNull(it.delegate.currentNavigator).route(location) }
        awaitDestination(scenario, location)
        return location
    }

    private fun launch() = ActivityScenario.launch<MainActivity>(
        Intent(ApplicationProvider.getApplicationContext(), MainActivity::class.java)
            .putExtra("APP_ROOT_URL", "http://127.0.0.1:1")
    )

    private fun awaitDestination(scenario: ActivityScenario<MainActivity>, location: String? = null) {
        val deadline = SystemClock.uptimeMillis() + 5_000
        var ready = false
        while (!ready && SystemClock.uptimeMillis() < deadline) {
            scenario.onActivity { activity ->
                val destination = activity.delegate.currentNavigator?.currentDestination
                ready = destination != null && (location == null || destination.location == location) &&
                    destination.fragment.view != null && destination.fragment.viewLifecycleOwner.lifecycle.currentState
                        .isAtLeast(Lifecycle.State.STARTED)
            }
            if (!ready) SystemClock.sleep(25)
        }
        assertTrue("Destination did not become ready: $location", ready)
    }
}
