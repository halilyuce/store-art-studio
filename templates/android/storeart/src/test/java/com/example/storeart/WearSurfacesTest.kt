package com.example.storeart

import org.junit.Assume.assumeTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * The Wear OS listing set, once per selected market, written to build/storeart/<market>/:
 *   wear_01_tile.png  wear_02_list.png  square, opaque, 576 x 576 px (192 dp at 3x)
 *
 * Play's Wear OS screenshots are square (1:1, at least 384 x 384 px) and show the watch UI only:
 * no round mask, no watch frame, no background or text around it. That is why these are not the
 * round cut-outs the phone page composites onto a wrist. The snapshot handler writes every "wear_"
 * id without alpha, on black. tools/stage-play.sh copies them to images/wearScreenshots/.
 *
 * Only if the app ships a Wear OS app or tile: the tests are skipped unless the config's
 * "surfaces" lists "wear".
 *
 * Render a few distinct states (a tile, a list, a detail), not one state twice. Swap the
 * SampleWear* placeholders for your Wear app's real composables; keep the "wear_NN_" prefix: Play shows them in name order.
 */
@RunWith(Parameterized::class)
class WearSurfacesTest(code: String) : StoreArtTest(CONFIG.byCode(code)) {

    @Before
    fun appHasWear() = assumeTrue("no \"wear\" in surfaces", CONFIG.has("wear"))

    @Test
    fun tile() = snapshot("wear_01_tile", WEAR_DP, WEAR_DP, dark = true) { SampleWearTile(world) }

    @Test
    fun list() = snapshot("wear_02_list", WEAR_DP, WEAR_DP, dark = true) { SampleWearList(world) }

    companion object {
        /** A large round watch is about 192 to 227 dp across. 192 dp at 3x is 576 px, above Play's 384 px minimum. */
        const val WEAR_DP = 192

        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun markets(): List<String> = CONFIG.selected().map { it.code }
    }
}
