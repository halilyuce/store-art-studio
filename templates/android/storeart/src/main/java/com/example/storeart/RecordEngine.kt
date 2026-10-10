package com.example.storeart

import kotlin.math.exp

/**
 * A seeded data engine. Hand-typed aggregates drift: a total on the widget stops matching the sum
 * on the list screen. Here every aggregate is computed from records, and the records come from a
 * seeded draw, so the same run gives the same numbers and every surface agrees.
 *
 * (In the sports app this came from, the records were results and the aggregates were tables. The
 * mechanism is the same for an expense tracker, a habit app or a delivery app.)
 *
 * [WorldSpec.items] are listed strongest first: the draw leans on that order, it does not dictate
 * it. The engine tries [SEED_TRIES] seeds from [WorldSpec.seed] and keeps the first whose outcome
 * fits the story: the user's primary item in the top two, and its latest record trending up (the
 * surfaces open on it). No seed fits: reorder the items or change the seed, never edit a number.
 */
data class ItemSpec(val id: String, val name: String, val short: String)

/** The item that is live at the frozen moment: [progress] percent done, started [startedMinutesAgo] ago. */
data class LiveSpec(val item: String, val progress: Int, val startedMinutesAgo: Int, val valueMinor: Long)

data class WorldSpec(
    val title: String,
    val titleImage: String,
    val items: List<ItemSpec>,
    val primary: String,
    val live: LiveSpec,
    val days: Int = 28,
    /** A typical record, in minor currency units (cents). */
    val baseValueMinor: Long = 4_000,
    val seed: Long = 1L,
)

/** An item as the surfaces show it: a name, a short label, an image URL. */
data class Item(val id: String, val name: String, val short: String, val image: String)

/** One dated value. Aggregates are only ever computed from these. */
data class ItemRecord(val item: Item, val at: Long, val valueMinor: Long)

/** An item's aggregate: [count] records, [totalMinor] their sum, [trendUp] its latest record beat the one before. */
data class Summary(val rank: Int, val item: Item, val count: Int, val totalMinor: Long, val trendUp: Boolean)

data class LiveState(val item: Item, val progress: Int, val startedAt: Long, val valueMinor: Long)

class RecordWorld(val records: List<ItemRecord>, val summaries: List<Summary>, val live: LiveState, val seed: Long)

object RecordEngine {
    const val SEED_TRIES = 64
    private const val DAY = 86_400_000L

    fun build(spec: WorldSpec, now: Long, image: (String) -> String): RecordWorld {
        require(spec.items.any { it.id == spec.primary }) { "Store art: primary '${spec.primary}' is not an item" }
        val items = spec.items.map { Item(it.id, it.name, it.short, image("item/${it.id}")) }
        return (0 until SEED_TRIES).asSequence()
            .map { build(spec, items, now, spec.seed + it) }
            .firstOrNull { fits(it, spec.primary) }
            ?: error("Store art: no seed in ${spec.seed}..${spec.seed + SEED_TRIES - 1} puts '${spec.primary}' in the top two, trending up. Reorder the items or change the seed.")
    }

    private fun fits(world: RecordWorld, primary: String): Boolean {
        val summary = world.summaries.first { it.item.id == primary }
        return summary.rank <= 2 && summary.trendUp
    }

    private fun build(spec: WorldSpec, items: List<Item>, now: Long, seed: Long): RecordWorld {
        val random = java.util.Random(seed)
        val n = items.size
        val records = buildList {
            for (day in spec.days downTo 1) {
                items.forEachIndexed { i, item ->
                    // Strength from 1.0 (first) down to 0.35 (last); the draw leans on it.
                    val strength = 1.0 - 0.65 * i / (n - 1).coerceAtLeast(1)
                    repeat(poisson(1.6 * strength, random)) { k ->
                        val value = (spec.baseValueMinor * (0.4 + random.nextDouble() * 1.2) * (0.6 + strength)).toLong()
                        add(ItemRecord(item, now - day * DAY + (9 + 3 * k) * 3_600_000L, value / 10 * 10))
                    }
                }
            }
        }
        val summaries = items.map { item ->
            val own = records.filter { it.item.id == item.id }
            val trendUp = own.size >= 2 && own[own.size - 1].valueMinor > own[own.size - 2].valueMinor
            Triple(item, own, trendUp)
        }.sortedWith(compareByDescending<Triple<Item, List<ItemRecord>, Boolean>> { (_, own) -> own.sumOf { it.valueMinor } }.thenBy { it.first.name })
            .mapIndexed { i, (item, own, trendUp) -> Summary(i + 1, item, own.size, own.sumOf { it.valueMinor }, trendUp) }
        val liveItem = items.first { it.id == spec.live.item }
        val live = LiveState(liveItem, spec.live.progress, now - spec.live.startedMinutesAgo * 60_000L, spec.live.valueMinor)
        return RecordWorld(records, summaries, live, seed)
    }

    private fun poisson(lambda: Double, random: java.util.Random): Int {
        val limit = exp(-lambda)
        var k = 0
        var p = random.nextDouble()
        while (p > limit) {
            k++
            p *= random.nextDouble()
        }
        return k
    }
}
