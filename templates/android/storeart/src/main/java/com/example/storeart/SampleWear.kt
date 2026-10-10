package com.example.storeart

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil3.compose.AsyncImage

/*
 * PLACEHOLDERS for a Wear OS listing. Play wants square screenshots of the watch UI only: no
 * round mask, no watch frame, no wrist, no text added around it. So these fill a square with the
 * watch's own black background and keep the content inside the round safe area, as the watch
 * draws it. Replace them with your Wear app's real composables (Compose for Wear OS renders in
 * Paparazzi like any composable). A tile built with ProtoLayout is not Compose: render a Compose
 * mirror of it from the same state and say so in the report, or capture it on a Wear emulator
 * that has no account (references/android-compose.md, "Wear OS").
 */

/** The watch background. Wear UIs are dark; the render has no light variant. */
private val WatchBlack = Color(0xFF000000)
private val WatchOnSurface = Color(0xFFF1F1F4)
private val WatchMuted = Color(0xFFB4B4BE)
private val WatchAccent = Color(0xFFA9A3FF)

/** The live state as a tile: `wear_01_tile`. */
@Composable
fun SampleWearTile(world: ShowcaseWorld, modifier: Modifier = Modifier) {
    val live = world.live
    Box(modifier.fillMaxSize().background(WatchBlack), contentAlignment = Alignment.Center) {
        // Everything inside the round safe area (about 15% in from each edge on a round watch).
        // Measure the column against it: 192 dp leaves about 136 dp, and a line that does not fit
        // is clipped silently, not flagged.
        Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.padding(28.dp)) {
            Text(
                stringResource(R.string.storeart_sample_live, live.progress),
                color = WatchAccent, fontSize = 12.sp, textAlign = TextAlign.Center, maxLines = 1
            )
            Spacer(Modifier.size(4.dp))
            AsyncImage(model = live.item.image, contentDescription = null, modifier = Modifier.size(24.dp))
            Spacer(Modifier.size(4.dp))
            Text(live.item.name, color = WatchOnSurface, fontSize = 14.sp, fontWeight = FontWeight.Medium, textAlign = TextAlign.Center, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text(formatMoney(live.valueMinor, world.market), color = WatchOnSurface, fontSize = 22.sp, fontWeight = FontWeight.Bold, maxLines = 1)
            Text(formatClock(live.startedAt, world.market, use24HourClock()), color = WatchMuted, fontSize = 12.sp, maxLines = 1)
        }
    }
}

/** The top of the list as a second watch screen: `wear_02_list`. A few distinct states read better than one state twice. */
@Composable
fun SampleWearList(world: ShowcaseWorld, modifier: Modifier = Modifier) {
    Box(modifier.fillMaxSize().background(WatchBlack), contentAlignment = Alignment.Center) {
        Column(Modifier.padding(horizontal = 30.dp, vertical = 26.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Text(world.title, color = WatchMuted, fontSize = 12.sp)
            Spacer(Modifier.size(6.dp))
            // Three rows fit the round safe area at 192 dp; a fourth is clipped at the bottom edge.
            // The row shows the count, not the amount: a long currency string (a right to left
            // market's above all) leaves no room for the name on a watch.
            world.summaries.take(3).forEach { row ->
                Row(Modifier.fillMaxWidth().padding(vertical = 3.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.Start) {
                    AsyncImage(model = row.item.image, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(6.dp))
                    Text(row.item.name, Modifier.weight(1f), color = WatchOnSurface, fontSize = 13.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    Spacer(Modifier.width(4.dp))
                    Text("${row.count}", color = WatchOnSurface, fontSize = 13.sp, fontWeight = FontWeight.Medium, maxLines = 1)
                }
            }
        }
    }
}
