import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Real signing key (2026-09-13, owner blocker: "Every release build...
// signed with Flutter's debug key. Google Play requires a real upload
// key"). key.properties is deliberately git-ignored — it holds the real
// keystore passwords — and CI/local builds without it fall back to the
// debug key so `flutter run --release`/a fresh clone still work, matching
// this codebase's existing "don't crash on a missing secret" posture for
// every other real credential (GEMINI_API_KEY, SENTRY_DSN, etc.).
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasRealKeystore = keystorePropertiesFile.exists()
if (hasRealKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.spekooh.spekooh"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.spekooh.spekooh"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasRealKeystore) {
            create("release") {
                // rootProject.file, not file() — key.properties' own
                // storeFile path (e.g. "keystore/upload-keystore.jks") is
                // relative to android/, but this build.gradle.kts lives
                // one level down in android/app/, where a plain file()
                // call would resolve it wrongly (found live: "Keystore
                // file '.../android/app/keystore/upload-keystore.jks' not
                // found").
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Real key.properties present (a real machine building a real
            // release) -> the real upload key. Otherwise (a fresh clone,
            // this session's own sandbox, CI without the secret) -> the
            // debug key, same fallback this file always had, so nothing
            // that doesn't need real signing ever breaks.
            signingConfig = if (hasRealKeystore) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
