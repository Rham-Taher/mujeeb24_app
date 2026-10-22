import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val requireReleaseSignature = System.getenv("MUJEEB_PRODUCTION_RELEASE") == "true"
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}
val productionSigningReady = listOf("keyAlias", "keyPassword", "storePassword", "storeFile")
    .all { !keystoreProperties.getProperty(it).isNullOrBlank() } &&
    keystoreProperties.getProperty("storeFile")?.let { file(it).isFile } == true
if (requireReleaseSignature && !productionSigningReady) {
    throw GradleException("Production Android build requires a valid release signing keystore.")
}


android {
    namespace = "com.mujeeb24.mujeeb24_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Application ID matching Mujeeb24 specification
        applicationId = "com.mujeeb24.mujeeb24_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["mujeebAppLabel"] = "مجيب 24 (تجريبي)"
    }

    signingConfigs {
        create("release") {
            val keyFile = keystoreProperties.getProperty("storeFile")
            if (keyFile != null) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keyFile)
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (requireReleaseSignature) {
                manifestPlaceholders["mujeebAppLabel"] = "مجيب 24"
                signingConfig = signingConfigs.getByName("release")
            } else {
                // QA-only: use a distinct package so it cannot replace the live app.
                applicationIdSuffix = ".preview"
                signingConfig = signingConfigs.getByName("debug")
            }
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
