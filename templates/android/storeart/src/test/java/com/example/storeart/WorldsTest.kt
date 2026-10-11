package com.example.storeart

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Every market's world holds together before anything renders: each market in the config has a
 * world, the primary item sits in the top two and trends up, every aggregate is the sum of its
 * records, and the live state is at the frozen moment. Prints each world for a read-through.
 * Plain JUnit, no Paparazzi: it runs in a second.
 */
class WorldsTest {

    @Test
    fun everyWorldHoldsTogether() = CONFIG.markets.forEach { market ->
        val world = showcaseWorld(market, CONFIG, LogoFiles.logos)
        println("===== ${market.code} (${world.records.size} records)")
        world.summaries.forEach { println("   %d %-24s %3d %s".format(it.rank, it.item.name, it.count, formatMoney(it.totalMinor, market))) }

        val primary = world.summaries.first { it.item == world.primary }
        assertTrue("${market.code}: primary in the top two (rank ${primary.rank})", primary.rank <= 2)
        assertTrue("${market.code}: primary trends up", primary.trendUp)
        world.summaries.forEach { summary ->
            val own = world.records.filter { it.item == summary.item }
            assertEquals("${market.code} ${summary.item.id} count", own.size, summary.count)
            assertEquals("${market.code} ${summary.item.id} total", own.sumOf { it.valueMinor }, summary.totalMinor)
        }
        assertEquals("${market.code}: ranks are 1..n", (1..world.summaries.size).toList(), world.summaries.map { it.rank })
        assertTrue("${market.code}: no record after now", world.records.all { it.at < world.now })
        assertTrue("${market.code}: live started before now", world.live.startedAt < world.now)
    }

    @Test
    fun selectionDefaultsToOneMarket() {
        assertEquals(listOf(CONFIG.byCode(CONFIG.defaultCode)), CONFIG.selected(raw = null))
        assertEquals(CONFIG.markets, CONFIG.selected(raw = "all"))
    }
}
