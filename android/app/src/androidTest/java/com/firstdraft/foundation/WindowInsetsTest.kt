package com.firstdraft.foundation

import android.content.Intent
import android.view.View
import android.view.ViewGroup
import androidx.core.graphics.Insets
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.test.core.app.ActivityScenario
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.filters.SdkSuppress
import com.firstdraft.foundation.generated.GeneratedApplication
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
@SdkSuppress(minSdkVersion = 30)
class WindowInsetsTest {
    @Test fun systemNavigationSpaceIsReservedOnceAcrossTheRootAndChildren() {
        val intent = Intent(ApplicationProvider.getApplicationContext(), MainActivity::class.java)
            .putExtra("APP_ROOT_URL", "http://127.0.0.1:1")
        ActivityScenario.launch<MainActivity>(intent).use { scenario ->
            scenario.onActivity { activity ->
                val root = activity.findViewById<View>(R.id.root)
                val tabs = activity.findViewById<View>(R.id.bottom_nav)
                var childBottom = -1
                val probe = View(activity)
                (root as ViewGroup).addView(probe, 0)
                ViewCompat.setOnApplyWindowInsetsListener(probe) { _, remaining ->
                    childBottom = remaining.getInsets(WindowInsetsCompat.Type.systemBars()).bottom
                    remaining
                }
                val insets = WindowInsetsCompat.Builder()
                    .setInsets(WindowInsetsCompat.Type.systemBars(), Insets.of(24, 32, 48, 64))
                    .build()
                ViewCompat.dispatchApplyWindowInsets(root, insets)
                assertEquals(24, root.paddingLeft)
                assertEquals(48, root.paddingRight)
                if (GeneratedApplication.entries.size > 1) {
                    assertEquals(0, root.paddingBottom)
                    assertEquals(64, childBottom)
                    assertEquals(0, tabs.paddingLeft)
                    assertEquals(0, tabs.paddingRight)
                    assertEquals(64, tabs.paddingBottom)
                } else {
                    assertEquals(64, root.paddingBottom)
                    assertEquals(0, childBottom)
                }
            }
        }
    }

    @Test fun keyboardSpaceIsConsumedButVisibilityReachesChildren() {
        val intent = Intent(ApplicationProvider.getApplicationContext(), MainActivity::class.java)
            .putExtra("APP_ROOT_URL", "http://127.0.0.1:1")
        ActivityScenario.launch<MainActivity>(intent).use { scenario ->
            scenario.onActivity { activity ->
                val root = activity.findViewById<View>(R.id.root)
                var childInsets: WindowInsetsCompat? = null
                val probe = View(activity)
                (root as ViewGroup).addView(probe, 0)
                ViewCompat.setOnApplyWindowInsetsListener(probe) { _, remaining ->
                    childInsets = remaining
                    remaining
                }
                val insets = WindowInsetsCompat.Builder()
                    .setInsets(WindowInsetsCompat.Type.systemBars(), Insets.of(0, 32, 0, 64))
                    .setInsets(WindowInsetsCompat.Type.ime(), Insets.of(0, 0, 0, 240))
                    .setVisible(WindowInsetsCompat.Type.ime(), true)
                    .build()
                ViewCompat.dispatchApplyWindowInsets(root, insets)
                assertEquals(240, root.paddingBottom)
                assertEquals(0, root.paddingTop)
                val remaining = requireNotNull(childInsets)
                assertEquals(32, remaining.getInsets(WindowInsetsCompat.Type.systemBars()).top)
                assertEquals(0, remaining.getInsets(WindowInsetsCompat.Type.systemBars()).bottom)
                assertEquals(0, remaining.getInsets(WindowInsetsCompat.Type.ime()).bottom)
                assertTrue(remaining.isVisible(WindowInsetsCompat.Type.ime()))
            }
        }
    }
}
