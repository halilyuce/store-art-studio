package com.example.storeart

import androidx.compose.runtime.Composable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.platform.LocalContext
import java.text.NumberFormat
import java.time.Instant
import java.time.format.DateTimeFormatter
import java.util.Currency

/**
 * The frozen world: one fixed moment and one complete data set per market, read by every surface
 * so a widget, a screen and a notification always agree. Replace the sample types with your app's
 * own models and fill them with invented but plausible data. Full lists: an empty or three-row
 * list reads as broken in store art.
 *
 * Rules that keep a render repeatable:
 * - [ShowcaseWorld.now] is the config's moment in the market's zone. Nothing in a rendered code
 *   path calls System.currentTimeMillis(); where app code reads the clock, give it a seam.
 * - The 12 or 24 hour clock comes from [LocalUse24HourClock], never from the device setting.
 * - The JVM default zone and locale are set from the market before each test (StoreArtSupport.kt).
 */

/**
 * The market's 12 or 24 hour clock. null means "ask the device", which is what a running app does.
 * Move this into your app's core module so its real time formatting reads it, then the store art
 * provides it and the app never notices.
 */
val LocalUse24HourClock = staticCompositionLocalOf<Boolean?> { null }

@Composable
fun use24HourClock(): Boolean =
    LocalUse24HourClock.current ?: android.text.format.DateFormat.is24HourFormat(LocalContext.current)

fun formatClock(millis: Long, market: Market, use24Hour: Boolean): String =
    DateTimeFormatter.ofPattern(if (use24Hour) "HH:mm" else "h:mm a", market.locale)
        .withZone(market.zone)
        .format(Instant.ofEpochMilli(millis))

/** Money in the market's currency and number format, from the config's currency code. */
fun formatMoney(minor: Long, market: Market): String =
    NumberFormat.getCurrencyInstance(market.locale).apply { currency = Currency.getInstance(market.currency) }
        .format(minor / 100.0)

/**
 * Logical image id to URL, from logos.json (committed). The renders serve each URL from a file that
 * scripts/fetch_logos.py downloaded; a running app would load the same URL from the network.
 */
class LogoUrls(private val urls: Map<String, String>) {
    fun url(id: String): String = urls[id] ?: error("Store art: no image URL for '$id' in logos.json")

    val all: Collection<String> get() = urls.values

    companion object {
        private val ENTRY = Regex("\"([^\"]+)\"\\s*:\\s*\"([^\"]+)\"")

        /** A flat {"id": "url"} object, the shape of logos.json. No JSON library needed. */
        fun parse(json: String): LogoUrls = LogoUrls(ENTRY.findAll(json).associate { it.groupValues[1] to it.groupValues[2] })
    }
}

/**
 * What every surface reads. One implementation per market, so a market can tell its own story (its
 * own names, amounts and primary item) while the surfaces and the page stay the same. Most markets
 * are a [WorldSpec] run through [RecordEngine]; a market that needs more can implement this by hand.
 */
interface ShowcaseWorld {
    val market: Market
    val now: Long
    val title: String
    val titleImage: String

    /** Every item, ranked by total. Computed from [records], never typed in. */
    val summaries: List<Summary>
    val records: List<ItemRecord>

    /** The user's primary item: the one the primary widget, the detail screen and the live card show. */
    val primary: Item
    val live: LiveState
}

private class SeededWorld(override val market: Market, config: StoreArtConfig, spec: WorldSpec, logos: LogoUrls) : ShowcaseWorld {
    override val now: Long = config.moment.atZone(market.zone).toInstant().toEpochMilli()
    private val built = RecordEngine.build(spec, now, logos::url)
    override val title = spec.title
    override val titleImage = logos.url(spec.titleImage)
    override val summaries = built.summaries
    override val records = built.records
    override val primary = built.summaries.first { it.item.id == spec.primary }.item
    override val live = built.live
}

/**
 * The world for [market], keyed by the config's market code: add a branch when you add a market to
 * storeart.config.json. These two are EXAMPLES (one left to right, one right to left) for a
 * fictional app that tracks spending across places. Replace them with your app's own data.
 */
fun showcaseWorld(market: Market, config: StoreArtConfig, logos: LogoUrls): ShowcaseWorld = when (market.code) {
    "us" -> SeededWorld(
        market, config, logos = logos, spec = WorldSpec(
            title = "This month",
            titleImage = "app/title",
            items = listOf(
                ItemSpec("harbor", "Harbor Studio", "HAR"),
                ItemSpec("ridge", "Ridge Market", "RID"),
                ItemSpec("lakeside", "Lakeside", "LAK"),
                ItemSpec("northgate", "Northgate", "NOR"),
                ItemSpec("summit", "Summit Hall", "SUM"),
                ItemSpec("riverton", "Riverton", "RIV"),
                ItemSpec("eastport", "Eastport", "EAS"),
                ItemSpec("westfield", "Westfield", "WES"),
            ),
            primary = "harbor",
            live = LiveSpec("harbor", progress = 72, startedMinutesAgo = 26, valueMinor = 4_850),
            seed = 11L,
        )
    )
    "sa" -> SeededWorld(
        market, config, logos = logos, spec = WorldSpec(
            title = "هذا الشهر",
            titleImage = "app/title",
            items = listOf(
                ItemSpec("harbor", "استوديو الميناء", "MIN"),
                ItemSpec("ridge", "سوق الهضبة", "HAD"),
                ItemSpec("lakeside", "البحيرة", "BUH"),
                ItemSpec("northgate", "البوابة الشمالية", "BAW"),
                ItemSpec("summit", "قاعة القمة", "QIM"),
                ItemSpec("riverton", "النهر", "NAH"),
                ItemSpec("eastport", "الشرق", "SHA"),
                ItemSpec("westfield", "الغرب", "GHA"),
            ),
            primary = "ridge",
            live = LiveSpec("ridge", progress = 64, startedMinutesAgo = 18, valueMinor = 12_500),
            baseValueMinor = 15_000,
            seed = 23L,
        )
    )
    else -> error("Store art: no world for market '${market.code}'. Add a branch in showcaseWorld() (SampleWorld.kt).")
}
