package com.example.storeart

import androidx.compose.runtime.Composable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.platform.LocalContext
import java.time.Instant
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * The frozen world: one fixed moment and one complete data set per market, read by every surface
 * so a widget, a screen and a notification always agree. Replace the sample types with your app's
 * own models and fill them with invented but plausible data. Full tables and full schedules: an
 * empty or three-row table reads as broken in store art.
 *
 * Rules that keep a render repeatable:
 * - [SampleWorld.now] is a constant. Nothing in a rendered code path calls System.currentTimeMillis();
 *   where app code reads the clock, give it a seam (a parameter or a CompositionLocal).
 * - The 12 or 24 hour clock comes from [LocalUse24HourClock], never from the device setting.
 * - The JVM default zone and locale are set from the market before each test (StoreArtSupport.kt).
 */

/** One store market: language, zone, clock, direction. [qualifier] is the resource qualifier Paparazzi takes. */
enum class Market(
    val code: String,
    val qualifier: String,
    val locale: Locale,
    val zone: ZoneId,
    val uses24HourClock: Boolean,
    val rtl: Boolean
) {
    US("us", "en-rUS", Locale.US, ZoneId.of("America/New_York"), uses24HourClock = false, rtl = false),
    SA("sa", "ar-rSA", Locale.forLanguageTag("ar-SA-u-nu-latn"), ZoneId.of("Asia/Riyadh"), uses24HourClock = false, rtl = true),
}

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

data class Team(val id: String, val name: String, val short: String, val logo: String)

data class TableRow(val rank: Int, val team: Team, val won: Int, val drawn: Int, val lost: Int) {
    val played: Int get() = won + drawn + lost
    val points: Int get() = won * 3 + drawn
}

data class Fixture(
    val home: Team,
    val away: Team,
    val kickoff: Long,
    val homeScore: Int? = null,
    val awayScore: Int? = null,
    val minute: Int? = null
) {
    val isLive: Boolean get() = minute != null
}

/**
 * Logical logo id to URL, from logos.json (committed). The renders serve each URL from a file that
 * scripts/fetch_logos.py downloaded; a running app would load the same URL from the network.
 */
class LogoUrls(private val urls: Map<String, String>) {
    fun url(id: String): String = urls[id] ?: error("Store art: no logo URL for '$id' in logos.json")

    val all: Collection<String> get() = urls.values

    companion object {
        private val ENTRY = Regex("\"([^\"]+)\"\\s*:\\s*\"([^\"]+)\"")

        /** A flat {"id": "url"} object, the shape of logos.json. No JSON library needed. */
        fun parse(json: String): LogoUrls = LogoUrls(ENTRY.findAll(json).associate { it.groupValues[1] to it.groupValues[2] })
    }
}

/**
 * Sunday 11 October 2026, 9:41 in the market's zone. A league eight games in: the followed team
 * leads and is playing live, the table adds up (points = 3 x won + drawn), and the same score
 * appears on every surface.
 */
class SampleWorld(val market: Market, logos: LogoUrls) {

    val now: Long = ZonedDateTime.of(2026, 10, 11, 9, 41, 0, 0, market.zone).toInstant().toEpochMilli()

    private fun team(id: String, name: String, short: String) = Team(id, name, short, logos.url("team/$id"))

    val harbor = team("harbor", "Harbor City", "HAR")
    val ridge = team("ridge", "Ridge United", "RID")
    private val lakeside = team("lakeside", "Lakeside", "LAK")
    private val northgate = team("northgate", "Northgate", "NOR")
    private val summit = team("summit", "Summit FC", "SUM")
    private val riverton = team("riverton", "Riverton", "RIV")
    private val eastport = team("eastport", "Eastport", "EAS")
    private val westfield = team("westfield", "Westfield", "WES")

    val leagueName: String = "Sample League"
    val leagueLogo: String = logos.url("league/main")

    /** Every team has played 8. Ordered by points, then by name. */
    val table: List<TableRow> = listOf(
        TableRow(1, harbor, 6, 1, 1),
        TableRow(2, ridge, 5, 2, 1),
        TableRow(3, lakeside, 5, 1, 2),
        TableRow(4, northgate, 4, 2, 2),
        TableRow(5, summit, 3, 2, 3),
        TableRow(6, riverton, 2, 2, 4),
        TableRow(7, eastport, 1, 3, 4),
        TableRow(8, westfield, 0, 1, 7),
    )

    private val hour = 3_600_000L

    /** Harbor City 2-1 Ridge United, 72 minutes in, kicked off at 8:30. */
    val liveFixture = Fixture(harbor, ridge, kickoff = now - 71 * 60_000L, homeScore = 2, awayScore = 1, minute = 72)

    val fixtures: List<Fixture> = listOf(
        Fixture(lakeside, harbor, kickoff = now - 7 * 24 * hour, homeScore = 0, awayScore = 3),
        liveFixture,
        Fixture(summit, northgate, kickoff = now + 6 * hour),
        Fixture(harbor, eastport, kickoff = now + 6 * 24 * hour + 2 * hour),
    )
}
