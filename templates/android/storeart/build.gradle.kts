// The store-art render module: a test-only Android library. Nothing depends on it.
//
//   python3 storeart/scripts/fetch_logos.py      once, and whenever logos.json changes
//   ./gradlew :storeart:recordPaparazziDebug     renders build/storeart/<market>/<id>.png
//       -Pstoreart.markets=us,sa (or STOREART_MARKETS=us,sa, or "all"); default market only when unset
//       -Pstoreart.config=<path> when the config is not at store/storeart.config.json
//   storeart/scripts/export.sh                   both, then copies the PNGs to the page kit
//
// Versions come from the catalog (see libs.versions.snippet.toml). If your build has convention
// plugins for Android libraries and Compose, apply those instead of the first two plugins and the
// android { } block, so this module builds like every other module.
//
// If the root build already declares AGP, Kotlin or Paparazzi (a plugins { } block with
// apply false, or a buildscript classpath), the catalog versions must be exactly those: Gradle
// refuses a second version of a plugin that is already on the classpath.
plugins {
    alias(libs.plugins.android.library)
    // Only when gradle.properties has android.builtInKotlin=false (the build opted out of AGP 9's
    // built-in Kotlin): uncomment, or no Kotlin compiles and every test "passes" as NO-SOURCE.
    // alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.paparazzi)
}

// A build without built-in Kotlin compiles unit tests against android.jar only (-no-jdk), so the
// tests cannot see java.awt.image.BufferedImage, which the Paparazzi snapshot handler takes. Put
// the JDK back for the unit test compilations, and fail loudly when the Kotlin plugin is missing.
if (providers.gradleProperty("android.builtInKotlin").orNull == "false") {
    check(plugins.hasPlugin("org.jetbrains.kotlin.android")) {
        "storeart: android.builtInKotlin=false, so apply alias(libs.plugins.kotlin.android) in storeart/build.gradle.kts"
    }
    tasks.matching { it.name.endsWith("UnitTestKotlin") }.configureEach {
        withGroovyBuilder { getProperty("compilerOptions").withGroovyBuilder { getProperty("noJdk").withGroovyBuilder { "set"(false) } } }
    }
}

android {
    namespace = "com.example.storeart"
    compileSdk = libs.versions.compileSdk.get().toInt()
    defaultConfig {
        minSdk = libs.versions.minSdk.get().toInt()
    }
    buildFeatures {
        compose = true
    }
}

// The developer's market list and the market selection reach the tests as system properties.
// The renders are the output, so the test task is never up to date.
val storeArtConfig = providers.gradleProperty("storeart.config")
    .orElse(rootProject.layout.projectDirectory.file("store/storeart.config.json").asFile.path)
val storeArtMarkets = providers.gradleProperty("storeart.markets")
    .orElse(providers.environmentVariable("STOREART_MARKETS"))
    .orElse("")
tasks.withType<Test>().configureEach {
    systemProperty("storeart.config", storeArtConfig.get())
    systemProperty("storeart.markets", storeArtMarkets.get())
    outputs.upToDateWhen { false }
    // WorldsTest prints each market's world for a read-through: show it in the console.
    testLogging.showStandardStreams = true
}

dependencies {
    // The modules that hold the composables, widgets and notification layouts you show:
    // implementation(projects.feature.home)
    // implementation(projects.widgets)

    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.glance.appwidget)
    implementation(libs.coil.compose)

    testImplementation(libs.junit4)
}
