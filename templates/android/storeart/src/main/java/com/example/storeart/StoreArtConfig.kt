package com.example.storeart

import java.io.File
import java.time.LocalDateTime
import java.time.ZoneId
import java.util.Locale

/**
 * One store market, as storeart.config.json describes it. The skill ships no market list: the
 * developer owns the config, and this module, the page kit and the render scripts all read it.
 *
 * [code] names the render folder (build/storeart/<code>/, then page/ui/<code>/). [appLocale] is
 * the resource qualifier Paparazzi takes ("en-rUS", "ar-rSA"). [locale] is what every formatter
 * reads, with the numbering system appended when the config asks for one ("latn" for Western
 * digits in a language that defaults to others).
 */
data class Market(
    val code: String,
    val storeLocale: String,
    val appLocale: String,
    val locale: Locale,
    val zone: ZoneId,
    val uses24HourClock: Boolean,
    val rtl: Boolean,
    val currency: String,
)

/**
 * storeart.config.json: the frozen [moment] (local wall-clock time, the same in every market's
 * zone), the [defaultCode] market, the [surfaces] the app has, and every market. Each market is
 * flat on purpose (no nesting), so it parses here without a JSON library and in the shell scripts
 * with python3. "surfaces" is the one top-level list.
 */
class StoreArtConfig(
    val moment: LocalDateTime,
    val defaultCode: String,
    val markets: List<Market>,
    val surfaces: Set<String> = setOf(SCREENS),
) {

    /**
     * Whether the app has [surface]. Phone screens are always there. Everything else is optional
     * and listed in the config only when the app ships it: "widgets", "notification" (a live
     * notification, a Live Update or a live card), "wear", "tablet". Tests for a surface the app
     * does not have are skipped, and the page leaves it out.
     */
    fun has(surface: String): Boolean = surface == SCREENS || surface in surfaces

    fun byCode(code: String): Market =
        markets.firstOrNull { it.code.equals(code.trim(), ignoreCase = true) }
            ?: error("Store art: no market '$code' in storeart.config.json (have ${markets.map { it.code }})")

    /**
     * The markets this run renders: -Pstoreart.markets=us,sa (or STOREART_MARKETS=us,sa), "all"
     * for every market, and only the default market when unset. One market first: render the
     * default, get it approved, then roll out.
     */
    fun selected(raw: String? = selection()): List<Market> = when {
        raw.isNullOrBlank() -> listOf(byCode(defaultCode))
        raw.trim().equals("all", ignoreCase = true) -> markets
        else -> raw.split(',', ' ').filter { it.isNotBlank() }.distinct().map(::byCode)
    }

    companion object {
        const val SCREENS = "screens"
        private val SURFACES = Regex("\"surfaces\"\\s*:\\s*\\[([^\\]]*)\\]")
        private val OBJECT = Regex("\\{[^{}]*\\}")
        private val FIELD = Regex("\"(\\w+)\"\\s*:\\s*(\"(?:[^\"\\\\]|\\\\.)*\"|true|false|-?\\d+(?:\\.\\d+)?)")

        /** Gradle passes the path (storeart/build.gradle.kts); a bare test run looks next to the page kit. */
        fun load(path: String = System.getProperty("storeart.config")?.takeIf { it.isNotBlank() } ?: "../store/storeart.config.json"): StoreArtConfig {
            val file = File(path)
            check(file.exists()) { "Store art: no config at ${file.absolutePath}. Copy templates/android/storeart.config.json or pass -Pstoreart.config=<path>" }
            return parse(file.readText())
        }

        fun parse(json: String): StoreArtConfig {
            val marketsStart = json.indexOf("\"markets\"").also { check(it >= 0) { "Store art: config has no \"markets\"" } }
            val top = fields(json.substring(0, marketsStart))
            // A missing "surfaces" means screens only: the default config works for any app.
            val surfaces = SURFACES.find(json)?.groupValues?.get(1)
                ?.split(',')?.map { it.trim().removeSurrounding("\"") }?.filter { it.isNotEmpty() }
                ?.toSet().orEmpty() + SCREENS
            val markets = OBJECT.findAll(json.substring(marketsStart)).map { fields(it.value) }.map { m ->
                fun s(key: String) = m[key] ?: error("Store art: market ${m["code"]} has no \"$key\"")
                val digits = m["digits"].orEmpty()
                Market(
                    code = s("code"),
                    storeLocale = s("storeLocale"),
                    appLocale = s("appLocale"),
                    locale = Locale.forLanguageTag(s("languageTag") + if (digits.isNotEmpty()) "-u-nu-$digits" else ""),
                    zone = ZoneId.of(s("timeZone")),
                    uses24HourClock = s("clock24h").toBoolean(),
                    rtl = s("rtl").toBoolean(),
                    currency = s("currency"),
                )
            }.toList()
            check(markets.isNotEmpty()) { "Store art: config lists no markets" }
            check(markets.map { it.code }.distinct().size == markets.size) { "Store art: duplicate market codes in config" }
            return StoreArtConfig(
                moment = LocalDateTime.parse(top["moment"] ?: error("Store art: config has no \"moment\"")),
                defaultCode = top["default"] ?: markets.first().code,
                markets = markets,
                surfaces = surfaces,
            )
        }

        private fun fields(text: String): Map<String, String> =
            FIELD.findAll(text).associate { it.groupValues[1] to it.groupValues[2].removeSurrounding("\"") }

        private fun selection(): String? =
            System.getProperty("storeart.markets")?.takeIf { it.isNotBlank() }
                ?: System.getenv("STOREART_MARKETS")?.takeIf { it.isNotBlank() }
    }
}
