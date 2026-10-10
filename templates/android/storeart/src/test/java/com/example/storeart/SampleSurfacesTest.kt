package com.example.storeart

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import org.junit.Test

/** The page's main colour: widgets in the "-dyn" renders take their Material You palette from it. */
private const val PAGE_SEED = 0xFF5B4BFF.toInt()

/**
 * The three kinds of surface, each light and dark, written to build/storeart/us/:
 *   card_score(-dark).png              a Compose cut-out on a transparent background
 *   widget_table_big(-dyn)(-dark).png  a real Glance widget through RemoteViews, plain and Material You
 *   screen_table(-dark).png            a full 412 x 915 dp screen, opaque
 * Swap the Sample* composables for your app's own; keep the ids stable, the page kit uses them.
 */
class SampleSurfacesTest : StoreArtTest(Market.US) {

    @Test
    fun scoreCard() = MODES.forEach { dark ->
        snapshot(id("card_score", dark), 360, 240, dark, shrink = true) {
            SampleScoreCard(world, world.liveFixture, Modifier.width(360.dp))
        }
    }

    /** A 4x3 widget at the size a Pixel launcher gives it (374 x 310 dp), not its minimum size. */
    @Test
    fun tableWidget() {
        // Decoded up front, on the test thread.
        val logos = LogoFiles.decodeAll()
        val size = DpSize(374.dp, 310.dp)
        MODES.forEach { dark ->
            listOf("widget_table_big" to null, "widget_table_big-dyn" to DynamicWallpaper(PAGE_SEED)).forEach { (base, wallpaper) ->
                snapshotView(id(base, dark), 374, 310, dark, wallpaper) {
                    val context = paparazzi.context
                    hostRemoteViews(context, renderGlance(context, size) { SampleTableWidget(world, logos) })
                }
            }
        }
    }

    @Test
    fun tableScreen() = MODES.forEach { dark ->
        snapshot(id("screen_table", dark), 412, 915, dark) {
            SampleTableScreen(world, Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background))
        }
    }
}

/** The same screen in the right-to-left market: build/storeart/sa/. Proves strings, direction and formats switch. */
class SampleSurfacesRtlTest : StoreArtTest(Market.SA) {

    @Test
    fun tableScreen() = MODES.forEach { dark ->
        snapshot(id("screen_table", dark), 412, 915, dark) {
            SampleTableScreen(world, Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background))
        }
    }
}
