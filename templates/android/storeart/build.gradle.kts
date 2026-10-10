// The store-art render module: a test-only Android library. Nothing depends on it.
//
//   python3 storeart/scripts/fetch_logos.py      once, and whenever logos.json changes
//   ./gradlew :storeart:recordPaparazziDebug     renders build/storeart/<market>/<id>.png
//   storeart/scripts/export.sh                   both, then copies the PNGs to the page kit
//
// Versions come from the catalog (see libs.versions.snippet.toml). If your build has convention
// plugins for Android libraries and Compose, apply those instead of the first two plugins and the
// android { } block, so this module builds like every other module.
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.paparazzi)
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
