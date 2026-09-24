package com.firstdraft.foundation

import android.content.Intent
import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.os.SystemClock
import androidx.test.core.app.ActivityScenario
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class RotationTest {
    @Test fun rotationKeepsTheActivityInstance() {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        assumeTrue("Requires a phone display that honors requested orientation",
            context.resources.configuration.smallestScreenWidthDp < 600)
        val intent = Intent(ApplicationProvider.getApplicationContext(), MainActivity::class.java)
            .putExtra("APP_ROOT_URL", "http://127.0.0.1:1")
        ActivityScenario.launch<MainActivity>(intent).use { scenario ->
            lateinit var original: MainActivity
            scenario.onActivity { original = it }
            val initial = original.resources.configuration.orientation
            val opposite = if (initial == Configuration.ORIENTATION_PORTRAIT) {
                Configuration.ORIENTATION_LANDSCAPE
            } else {
                Configuration.ORIENTATION_PORTRAIT
            }
            for (orientation in listOf(opposite, initial)) {
                scenario.onActivity {
                    it.requestedOrientation = if (orientation == Configuration.ORIENTATION_LANDSCAPE) {
                        ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE
                    } else {
                        ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
                    }
                }
                val deadline = SystemClock.uptimeMillis() + 5_000
                var actual = Configuration.ORIENTATION_UNDEFINED
                while (actual != orientation && SystemClock.uptimeMillis() < deadline) {
                    SystemClock.sleep(50)
                    scenario.onActivity { actual = it.resources.configuration.orientation }
                }
                assertEquals("The device must actually rotate", orientation, actual)
                lateinit var current: MainActivity
                scenario.onActivity { current = it }
                assertSame("Rotation must preserve the activity", original, current)
            }
        }
    }
}
