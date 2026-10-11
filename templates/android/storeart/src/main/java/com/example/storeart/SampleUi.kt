package com.example.storeart

import android.graphics.Bitmap
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Card
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.background
import androidx.glance.layout.Alignment as GlanceAlignment
import androidx.glance.layout.Column as GlanceColumn
import androidx.glance.layout.Row as GlanceRow
import androidx.glance.layout.Spacer as GlanceSpacer
import androidx.glance.layout.fillMaxSize as glanceFillMaxSize
import androidx.glance.layout.fillMaxWidth as glanceFillMaxWidth
import androidx.glance.layout.padding as glancePadding
import androidx.glance.layout.size as glanceSize
import androidx.glance.layout.width as glanceWidth
import androidx.glance.text.FontFamily
import androidx.glance.text.Text as GlanceText
import androidx.glance.text.TextStyle
import coil3.compose.AsyncImage
import androidx.glance.text.FontWeight as GlanceFontWeight

/*
 * PLACEHOLDERS. These three stand in for your app's real composables so the template renders on
 * its own. Delete this file once the tests render your own card, widget content and screen. Store
 * art never redraws app UI: if a real composable cannot render host-less, give it a seam (plain
 * state in, a clock parameter) instead of copying it here.
 */

/** A Compose card that loads its image by URL, as app code does. Rendered as a cut-out: `card_live`. */
@Composable
fun SampleLiveCard(world: ShowcaseWorld, live: LiveState, modifier: Modifier = Modifier) {
    Card(modifier) {
        Column(Modifier.padding(16.dp)) {
            Text(
                text = stringResource(R.string.storeart_sample_live, live.progress) + "  " +
                    formatClock(live.startedAt, world.market, use24HourClock()),
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.primary
            )
            Spacer(Modifier.size(12.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                AsyncImage(model = live.item.image, contentDescription = null, modifier = Modifier.size(40.dp))
                Text(live.item.name, Modifier.padding(horizontal = 12.dp).weight(1f), fontWeight = FontWeight.SemiBold)
                Text(formatMoney(live.valueMinor, world.market), fontSize = 24.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.End)
            }
        }
    }
}

/** A full list screen, `screen_list`. The caller paints the background; the status bar belongs to the page layer. */
@Composable
fun SampleListScreen(world: ShowcaseWorld, modifier: Modifier = Modifier) {
    Column(modifier.padding(horizontal = 16.dp)) {
        Spacer(Modifier.size(24.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            AsyncImage(model = world.titleImage, contentDescription = null, modifier = Modifier.size(36.dp))
            Spacer(Modifier.width(12.dp))
            Text(world.title, style = MaterialTheme.typography.headlineSmall)
        }
        Spacer(Modifier.size(16.dp))
        SampleLiveCard(world, world.live, Modifier.fillMaxWidth())
        Spacer(Modifier.size(24.dp))
        Text(stringResource(R.string.storeart_sample_list), style = MaterialTheme.typography.titleMedium)
        Spacer(Modifier.size(8.dp))
        world.summaries.forEach { row ->
            Row(Modifier.fillMaxWidth().padding(vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
                Text("${row.rank}", Modifier.width(28.dp), color = MaterialTheme.colorScheme.onSurfaceVariant)
                AsyncImage(model = row.item.image, contentDescription = null, modifier = Modifier.size(28.dp))
                Text(row.item.name, Modifier.padding(start = 12.dp).weight(1f))
                Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                    Text("${row.count}", color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text(formatMoney(row.totalMinor, world.market), fontWeight = FontWeight.Bold)
                }
            }
            HorizontalDivider()
        }
    }
}

/**
 * Glance widget content, `widget_list_big`: what a GlanceAppWidget's provideContent would show,
 * taking plain state so a test can compose it with GlanceRemoteViews. [images] are decoded up
 * front (on the test thread); a running widget would load them in its provider. The LazyColumn is
 * why the test needs an AppWidgetHostView parent: RemoteViews collections only fill inside one.
 */
@Composable
fun SampleListWidget(world: ShowcaseWorld, images: Map<String, Bitmap>) {
    // System families only: a RemoteViews widget cannot load a bundled font.
    val medium = FontFamily("sans-serif-medium")
    GlanceTheme {
        GlanceColumn(
            GlanceModifier.glanceFillMaxSize()
                .background(GlanceTheme.colors.widgetBackground)
                .cornerRadius(24.dp)
                .glancePadding(16.dp)
        ) {
            GlanceRow(verticalAlignment = GlanceAlignment.CenterVertically) {
                images[world.titleImage]?.let { Image(ImageProvider(it), contentDescription = null, modifier = GlanceModifier.glanceSize(24.dp)) }
                GlanceSpacer(GlanceModifier.glanceWidth(8.dp))
                GlanceText(
                    world.title,
                    style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 16.sp, fontWeight = GlanceFontWeight.Medium, fontFamily = medium)
                )
            }
            GlanceSpacer(GlanceModifier.glanceSize(8.dp))
            LazyColumn {
                items(world.summaries, itemId = { it.rank.toLong() }) { row ->
                    GlanceRow(GlanceModifier.glanceFillMaxWidth().glancePadding(vertical = 4.dp), verticalAlignment = GlanceAlignment.CenterVertically) {
                        GlanceText("${row.rank}", GlanceModifier.glanceWidth(20.dp), style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant, fontSize = 13.sp))
                        images[row.item.image]?.let { Image(ImageProvider(it), contentDescription = null, modifier = GlanceModifier.glanceSize(18.dp)) }
                        GlanceSpacer(GlanceModifier.glanceWidth(8.dp))
                        GlanceText(row.item.name, GlanceModifier.defaultWeight(), style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 13.sp))
                        GlanceText(
                            formatMoney(row.totalMinor, world.market),
                            style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 13.sp, fontWeight = GlanceFontWeight.Medium, fontFamily = medium)
                        )
                    }
                }
            }
        }
    }
}
