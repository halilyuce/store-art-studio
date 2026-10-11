package com.example.storeart

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/** The page's main colour: widgets in the "-dyn" renders take their Material You palette from it. */
private const val PAGE_SEED = 0xFF5B4BFF.toInt()

/**
 * Three kinds of surface, each light and dark, once per selected market, written to
 * build/storeart/<market>/ under ROLE ids, so one page layout works for every market:
 *   card_live(-dark).png                a Compose cut-out on a transparent background
 *   widget_list_big(-dyn)(-dark).png    a real Glance widget through RemoteViews, plain and Material You
 *   screen_list(-dark).png              a full 412 x 915 dp screen, opaque
 * A role names what a surface does on the page (widget_primary_big, widget_list_wide, card_live,
 * card_live_2, screen_detail, screen_list, screen_secondary), never what it shows in one market.
 * Swap the Sample* composables for your app's own; keep the ids stable, the page kit uses them.
 *
 * Only screens are required. The card renders when the config's "surfaces" lists "notification",
 * the widget when it lists "widgets"; otherwise those tests are skipped, not failed.
 *
 * Markets: -Pstoreart.markets=us,sa or STOREART_MARKETS=us,sa, "all" for every market in
 * storeart.config.json, the default market only when unset.
 */
@RunWith(Parameterized::class)
class SampleSurfacesTest(code: String) : StoreArtTest(CONFIG.byCode(code)) {

    @Test
    fun liveCard() {
        assumeTrue("no \"notification\" in surfaces", CONFIG.has("notification"))
        MODES.forEach { dark ->
            snapshot(id("card_live", dark), 360, 240, dark, shrink = true) {
                SampleLiveCard(world, world.live, Modifier.width(360.dp))
            }
        }
    }

    /** A 4x3 widget at the size a Pixel launcher gives it (374 x 310 dp), not its minimum size. */
    @Test
    fun listWidget() {
        assumeTrue("no \"widgets\" in surfaces", CONFIG.has("widgets"))
        // Decoded up front, on the test thread.
        val images = LogoFiles.decodeAll()
        val size = DpSize(374.dp, 310.dp)
        MODES.forEach { dark ->
            listOf("widget_list_big" to null, "widget_list_big-dyn" to DynamicWallpaper(PAGE_SEED)).forEach { (base, wallpaper) ->
                snapshotView(id(base, dark), 374, 310, dark, wallpaper) {
                    val context = paparazzi.context
                    hostRemoteViews(context, renderGlance(context, size) { SampleListWidget(world, images) })
                }
            }
        }
    }

    @Test
    fun listScreen() = MODES.forEach { dark ->
        snapshot(id("screen_list", dark), 412, 915, dark) {
            SampleListScreen(world, Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background))
        }
    }

    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun markets(): List<String> = CONFIG.selected().map { it.code }
    }
}
