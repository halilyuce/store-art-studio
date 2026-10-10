package com.example.storeart

import android.appwidget.AppWidgetHostView
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.RemoteViews
import androidx.activity.compose.LocalActivityResultRegistryOwner
import androidx.activity.result.ActivityResultRegistry
import androidx.activity.result.ActivityResultRegistryOwner
import androidx.activity.result.contract.ActivityResultContract
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.size
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.LocalInspectionMode
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.core.app.ActivityOptionsCompat
import androidx.glance.appwidget.ExperimentalGlanceRemoteViewsApi
import androidx.glance.appwidget.GlanceRemoteViews
import app.cash.paparazzi.DeviceConfig
import app.cash.paparazzi.Paparazzi
import app.cash.paparazzi.Snapshot
import app.cash.paparazzi.SnapshotHandler
import coil3.annotation.ExperimentalCoilApi
import coil3.asImage
import coil3.compose.AsyncImagePreviewHandler
import coil3.compose.LocalAsyncImagePreviewHandler
import com.android.ide.common.rendering.api.SessionParams.RenderingMode
import com.android.resources.Density
import com.android.resources.NightMode
import com.android.resources.ScreenOrientation
import java.awt.image.BufferedImage
import java.io.File
import java.security.MessageDigest
import java.util.Collections
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.ConcurrentHashMap
import javax.imageio.ImageIO
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Before
import org.junit.Rule

/*
 * The store-art renderer on Paparazzi (layoutlib on the JVM): no emulator, no device, no app
 * install, no network, no account. Proven with Paparazzi 2.0.0-alpha05 on AGP 9.3, Kotlin 2.4,
 * compileSdk 36/37, Gradle 9.7, JDK 21.
 * Every trap these helpers work around is in references/android-compose.md under "What broke".
 *
 * Gradle runs unit tests with the module folder as the working directory, so the relative paths
 * below (logos.json, src/test/resources/logos, build/storeart) are module paths. The market list
 * is storeart.config.json, which Gradle passes as -Dstoreart.config (see build.gradle.kts).
 */

/** The developer's storeart.config.json: the frozen moment and every market. */
internal val CONFIG: StoreArtConfig by lazy { StoreArtConfig.load() }

/** xxhdpi: 1 dp is 3 px. A 412 x 915 dp screen renders 1236 x 2745 px. */
internal const val DENSITY = 3

/** Where renders land: build/storeart/<market>/<id>.png. scripts/export.sh copies them to the page kit. */
internal fun storeArtDir(market: Market): File = File("build/storeart/${market.code}")

/** Surfaces that do not paint a background (cards, chips, widget corners, a round face) keep their alpha. */
internal const val TRANSPARENT_THEME = "android:Theme.Translucent.NoTitleBar.Fullscreen"

/**
 * Writes each snapshot as build/storeart/<market>/<name>.png, alpha kept ("wear_" ids are
 * flattened on black: Play's Wear OS screenshots ship as rendered). The renders are the
 * output, not goldens to compare, so record and verify runs both write them. For a gif() snapshot
 * every frame overwrites the file and the last (settled) frame stays.
 */
internal class StoreArtSnapshotHandler(private val market: Market) : SnapshotHandler {
    override fun newFrameHandler(snapshot: Snapshot, frameCount: Int, fps: Int): SnapshotHandler.FrameHandler {
        val name = requireNotNull(snapshot.name) { "Store art snapshots are written by name: pass one" }
        return object : SnapshotHandler.FrameHandler {
            override fun handle(image: BufferedImage) {
                val file = File(storeArtDir(market), "$name.png").apply { parentFile.mkdirs() }
                ImageIO.write(if (name.startsWith(OPAQUE_PREFIX)) onBlack(image) else image, "png", file)
            }

            override fun close() = Unit
        }
    }

    override fun close() = Unit

    private companion object {
        /** Wear OS listing screenshots ship as they render: square and with no alpha channel. */
        const val OPAQUE_PREFIX = "wear_"

        fun onBlack(image: BufferedImage): BufferedImage =
            BufferedImage(image.width, image.height, BufferedImage.TYPE_INT_RGB).apply {
                val g = createGraphics()
                g.color = java.awt.Color.BLACK
                g.fillRect(0, 0, width, height)
                g.drawImage(image, 0, 0, null)
                g.dispose()
            }
    }
}

/** A device exactly [widthDp] x [heightDp] at xxhdpi, in [market]'s locale, font scale 1. */
internal fun storeArtDevice(widthDp: Int, heightDp: Int, dark: Boolean, market: Market): DeviceConfig =
    DeviceConfig.PIXEL_6.copy(
        screenWidth = widthDp * DENSITY,
        screenHeight = heightDp * DENSITY,
        xdpi = 480,
        ydpi = 480,
        density = Density.XXHIGH,
        fontScale = 1f,
        locale = market.appLocale,
        nightMode = if (dark) NightMode.NIGHT else NightMode.NOTNIGHT,
        // Layoutlib lays a portrait screen out tall side down: a wide surface needs landscape.
        orientation = if (widthDp > heightDp) ScreenOrientation.LANDSCAPE else ScreenOrientation.PORTRAIT,
        softButtons = false
    )

/**
 * The image files scripts/fetch_logos.py downloaded: a URL's file is src/test/resources/logos/
 * <sha1 of the URL>.png. A URL with no file fails the render, loudly. A missing image must never
 * ship as a blank space.
 */
internal object LogoFiles {
    private val dir = File("src/test/resources/logos")
    val logos: LogoUrls by lazy { LogoUrls.parse(File("logos.json").readText()) }
    val misses: MutableSet<String> = Collections.synchronizedSet(mutableSetOf())
    private val cache = ConcurrentHashMap<String, Bitmap>()

    fun fileFor(url: String): File {
        val sha = MessageDigest.getInstance("SHA-1").digest(url.toByteArray()).joinToString("") { "%02x".format(it) }
        return File(dir, "$sha.png")
    }

    fun assertAllFetched() {
        val missing = logos.all.filterNot { fileFor(it).exists() }
        check(missing.isEmpty()) { "Images not fetched (run python3 storeart/scripts/fetch_logos.py): $missing" }
    }

    /**
     * Every image, decoded now. Call it on the test thread: decoding on Coil's background threads
     * inside layoutlib can abort the JVM with no stack trace.
     */
    fun decodeAll(): Map<String, Bitmap> = logos.all.associateWith { bitmap(it) }

    fun bitmap(data: Any?): Bitmap {
        val url = data?.toString().orEmpty()
        val file = fileFor(url)
        if (!file.exists()) {
            misses += url
            throw AssertionError("No image file for '$url' (not in logos.json, or not fetched)")
        }
        // BitmapFactory.decodeFile calls fstat through libcore, which layoutlib does not back. Bytes decode fine.
        return cache.getOrPut(url) {
            file.readBytes().let { BitmapFactory.decodeByteArray(it, 0, it.size) }
                ?: throw AssertionError("Image file for '$url' does not decode: $file").also { misses += url }
        }
    }

    fun assertNoMisses() = check(misses.isEmpty()) { "Images requested that have no file: $misses" }
}

/** The market's zone and locale as JVM defaults: formatting code that takes neither reads them. */
internal fun useMarketDefaults(market: Market) {
    TimeZone.setDefault(TimeZone.getTimeZone(market.zone))
    Locale.setDefault(market.locale)
}

/**
 * [content] as Studio previews draw it (LocalInspectionMode, so entrance animations and preview
 * handlers apply), with every Coil image served from the fetched files, the market's 12 or 24 hour
 * clock, its layout direction, and a no-op activity result registry (screens that call
 * rememberLauncherForActivityResult crash without one).
 */
@OptIn(ExperimentalCoilApi::class)
@Composable
internal fun StoreArtContent(market: Market, content: @Composable () -> Unit) {
    val images = AsyncImagePreviewHandler { request -> LogoFiles.bitmap(request.data).asImage() }
    CompositionLocalProvider(
        LocalInspectionMode provides true,
        LocalAsyncImagePreviewHandler provides images,
        LocalUse24HourClock provides market.uses24HourClock,
        // Library modules have no android:supportsRtl, so Compose would stay left to right.
        LocalLayoutDirection provides if (market.rtl) LayoutDirection.Rtl else LayoutDirection.Ltr,
        LocalActivityResultRegistryOwner provides NoActivityResults,
        content = content
    )
}

private object NoActivityResults : ActivityResultRegistryOwner {
    override val activityResultRegistry = object : ActivityResultRegistry() {
        override fun <I, O> onLaunch(requestCode: Int, contract: ActivityResultContract<I, O>, input: I, options: ActivityOptionsCompat?) = Unit
    }
}

/**
 * Glance content composed into RemoteViews in-process, as a placed widget would get them. One
 * composition: state that arrives later (an image load) never reaches the result, so pass decoded
 * bitmaps in, or compose twice (first pass fills a cache, second draws from it).
 */
@OptIn(ExperimentalGlanceRemoteViewsApi::class)
internal fun renderGlance(context: Context, size: DpSize, content: @Composable () -> Unit): RemoteViews =
    runBlocking { GlanceRemoteViews().compose(context, size, content = content).remoteViews }

/** [views] applied inside an AppWidgetHostView: RemoteViews collections (a Glance LazyColumn) only fill inside one. */
internal fun hostRemoteViews(context: Context, views: RemoteViews): View =
    AppWidgetHostView(context).apply {
        addView(views.apply(context, this), FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
    }

/**
 * The home-screen wallpaper a render's Material You colours come from. Layoutlib runs the real
 * wallpaper -> seed -> tonal-spot pipeline into android.R.color.system_* when the session carries
 * RenderParamsFlags.FLAG_KEY_WALLPAPER_PATH (Studio's preview "Wallpaper" option), so GlanceTheme
 * and system_accent colours render as on a phone with that wallpaper. [seed] is drawn as a solid
 * image, so the extracted seed is that colour. Use your page background's main colour.
 */
data class DynamicWallpaper(val seed: Int) {
    /** The classpath path layoutlib loads with getResourceAsStream. */
    val resourcePath: String
        get() {
            val name = "seed_%06x.png".format(seed and 0xFFFFFF)
            // The test resources output folder is on the classpath as a directory: a file written there now is found.
            val marker = requireNotNull(DynamicWallpaper::class.java.classLoader!!.getResource("$FOLDER/README.txt")) {
                "src/test/resources/$FOLDER/README.txt is not on the test classpath"
            }
            val file = File(File(marker.toURI()).parentFile, name)
            if (!file.exists()) {
                val image = BufferedImage(SIZE_PX, SIZE_PX, BufferedImage.TYPE_INT_RGB)
                image.createGraphics().apply {
                    color = java.awt.Color(seed and 0xFFFFFF)
                    fillRect(0, 0, SIZE_PX, SIZE_PX)
                    dispose()
                }
                ImageIO.write(image, "png", file)
            }
            return "/$FOLDER/$name"
        }

    private companion object {
        const val FOLDER = "storeart-wallpapers"
        const val SIZE_PX = 64
    }
}

/**
 * Sets (or with null clears) the wallpaper the next Paparazzi session takes its dynamic colours
 * from. FRAGILE: Paparazzi 2.0.0-alpha05 has no API for render flags, so this reaches by reflection
 * into its shared SessionParamsBuilder, which unsafeUpdateConfig copies (flags included) into the
 * next session. Any Paparazzi release can rename these internals. If it throws, or the "-dyn"
 * renders match the plain ones, the reflection broke: drop the -dyn renders or update the names.
 */
internal fun setSessionWallpaper(wallpaper: DynamicWallpaper?) {
    val sdk = Class.forName("app.cash.paparazzi.PaparazziSdk")
    val companion = sdk.getField("Companion").get(null)
    val builder = companion.javaClass.getDeclaredMethod("getSessionParamsBuilder\$paparazzi").invoke(companion)
    val field = builder.javaClass.getDeclaredField("flags").apply { isAccessible = true }
    @Suppress("UNCHECKED_CAST")
    val flags = (field.get(builder) as Map<Any, Any>).toMutableMap()
    val key = Class.forName("com.android.layoutlib.bridge.android.RenderParamsFlags")
        .getField("FLAG_KEY_WALLPAPER_PATH").get(null)!!
    if (wallpaper == null) flags.remove(key) else flags[key] = wallpaper.resourcePath
    field.set(builder, flags)
}

/**
 * One store-art surface per call. [snapshot] renders Compose content, [snapshotView] a plain View
 * (applied RemoteViews). Both size the device to the surface and write <id>.png for [market].
 */
abstract class StoreArtTest(protected val market: Market) {

    @get:Rule
    val paparazzi = Paparazzi(
        deviceConfig = storeArtDevice(412, 915, dark = false, market = market),
        theme = TRANSPARENT_THEME,
        // AppCompat's inflater swaps in AppCompatImageView, which RemoteViews cannot drive.
        appCompatEnabled = false,
        // Without it layoutlib resolves every View (applied RemoteViews: a widget) left to right,
        // whatever the locale: library modules have no android:supportsRtl. LTR markets are unaffected.
        supportsRtl = true,
        snapshotHandler = StoreArtSnapshotHandler(market),
        useDeviceResolution = true
    )

    protected val world: ShowcaseWorld by lazy { showcaseWorld(market, CONFIG, LogoFiles.logos) }

    @Before
    fun marketDefaults() {
        LogoFiles.assertAllFetched()
        useMarketDefaults(market)
    }

    @After
    fun noMissingImages() = LogoFiles.assertNoMisses()

    protected fun id(base: String, dark: Boolean) = if (dark) "$base-dark" else base

    /**
     * [content] in the app theme at [widthDp] x [heightDp], animations run [settleMillis] in.
     * [shrink] crops the image to the content's own size ([widthDp] x [heightDp] is then only the
     * room it gets), for cut-outs like a card or a notification. [wallpaper] gives the system
     * dynamic colours.
     */
    protected fun snapshot(
        id: String,
        widthDp: Int,
        heightDp: Int,
        dark: Boolean,
        shrink: Boolean = false,
        wallpaper: DynamicWallpaper? = null,
        settleMillis: Long = SETTLE_MILLIS,
        content: @Composable BoxScope.() -> Unit
    ) = withWallpaper(wallpaper) {
        paparazzi.unsafeUpdateConfig(
            deviceConfig = storeArtDevice(widthDp, heightDp, dark, market),
            renderingMode = if (shrink) RenderingMode.SHRINK else RenderingMode.NORMAL
        )
        val view = ComposeView(paparazzi.context).apply {
            setContent {
                AppTheme(dark) {
                    // A composable drawn without its Scaffold or Surface gets black text by default
                    // (LocalContentColor), unreadable on a dark background. Give it the theme's.
                    CompositionLocalProvider(LocalContentColor provides MaterialTheme.colorScheme.onBackground) {
                    StoreArtContent(market) {
                        val box = if (shrink) Modifier else Modifier.size(widthDp.dp, heightDp.dp)
                        Box(box, contentAlignment = Alignment.Center, content = content)
                    }
                    }
                }
            }
        }
        // Frames stepped to settleMillis, the last one kept: a single frame at an offset does not
        // advance LaunchedEffect-driven animations.
        paparazzi.gif(view, name = id, start = 0L, end = settleMillis, fps = SETTLE_FPS)
    }

    /** A plain View surface, [widthDp] x [heightDp]: applied RemoteViews (a widget, a notification body). */
    protected fun snapshotView(
        id: String,
        widthDp: Int,
        heightDp: Int,
        dark: Boolean,
        wallpaper: DynamicWallpaper? = null,
        view: () -> View
    ) = withWallpaper(wallpaper) {
        paparazzi.unsafeUpdateConfig(deviceConfig = storeArtDevice(widthDp, heightDp, dark, market), renderingMode = RenderingMode.NORMAL)
        val surface = view()
        // Mirrored only with supportsRtl = true on the Paparazzi rule (above): open the render and check it.
        if (market.rtl) surface.layoutDirection = View.LAYOUT_DIRECTION_RTL
        paparazzi.snapshot(surface, name = id)
    }

    private fun withWallpaper(wallpaper: DynamicWallpaper?, block: () -> Unit) {
        setSessionWallpaper(wallpaper)
        try {
            block()
        } finally {
            setSessionWallpaper(null)
        }
    }

    companion object {
        /** Long enough for entrance animations and crossfades. */
        const val SETTLE_MILLIS = 2_000L
        const val SETTLE_FPS = 6
        val MODES = listOf(false, true)
    }
}

/** Replace with your app's theme composable (the one its screens use), so renders match the app. */
@Composable
internal fun AppTheme(dark: Boolean, content: @Composable () -> Unit) =
    MaterialTheme(colorScheme = if (dark) darkColorScheme() else lightColorScheme(), content = content)
