plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

val pluginName = "OfficeGameAndroid"
val pluginPackageName = "ru.alfaoffice.game.android"
val godotVersion = "4.7.2.stable"
// Output folder of the Godot editor plugin that ships the AAR with the exported app.
val addonBin = rootProject.file("../../client/addons/office_game_android/bin")

android {
    namespace = pluginPackageName
    compileSdk = 36

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        minSdk = 24
        manifestPlaceholders["godotPluginName"] = pluginName
        manifestPlaceholders["godotPluginPackageName"] = pluginPackageName
        buildConfigField("String", "GODOT_PLUGIN_NAME", "\"$pluginName\"")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

// Keep in sync with DEPENDENCIES in client/addons/office_game_android/export_plugin.gd:
// an AAR does not carry its dependencies, the Godot export adds them to the app.
dependencies {
    compileOnly("org.godotengine:godot:$godotVersion")
    implementation("androidx.camera:camera-core:1.4.2")
    implementation("androidx.camera:camera-camera2:1.4.2")
    implementation("androidx.camera:camera-lifecycle:1.4.2")
    implementation("com.google.mlkit:barcode-scanning:17.3.0")
    implementation("com.google.mlkit:face-detection:16.1.7")
    implementation("com.google.mlkit:image-labeling:17.0.9")
    implementation("com.google.mlkit:pose-detection:18.0.0-beta5")
    implementation("org.opencv:opencv:4.12.0")
}

for (buildType in listOf("debug", "release")) {
    val copyTask = tasks.register<Copy>("copy${buildType.replaceFirstChar { it.uppercase() }}AarToAddon") {
        description = "Copies the $buildType AAR into the Godot editor plugin."
        from(layout.buildDirectory.dir("outputs/aar"))
        include("plugin-$buildType.aar")
        into(File(addonBin, buildType))
        rename { "office-game-android-$buildType.aar" }
    }
    afterEvaluate {
        tasks.named("assemble${buildType.replaceFirstChar { it.uppercase() }}").configure {
            finalizedBy(copyTask)
        }
    }
}
