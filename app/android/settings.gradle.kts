pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // Pinned to the latest stable 8.x line, not the template default (9.0.1): AGP 9 deprecates
    // legacy per-plugin `apply plugin: 'kotlin-android'`, which several real dependencies here
    // (file_picker, flutter_plugin_android_lifecycle) still use — mid-transition, different
    // plugins in the graph end up wanting opposite android.builtInKotlin settings, which isn't
    // resolvable by flag-tuning. 8.13.2 still supports compileSdk 36 without any of that.
    id("com.android.application") version "8.13.2" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")
