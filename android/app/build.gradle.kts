plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.io.FileInputStream
import java.util.Properties

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()

if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

val storeFilePathFromProps: String? = keystoreProperties.getProperty("storeFile")
val resolvedReleaseKeystoreFile =
    if (!storeFilePathFromProps.isNullOrBlank()) rootProject.file(storeFilePathFromProps) else null

val hasValidReleaseSigning: Boolean =
    keystorePropertiesFile.exists() &&
        !storeFilePathFromProps.isNullOrBlank() &&
        !keystoreProperties.getProperty("storePassword").isNullOrBlank() &&
        !keystoreProperties.getProperty("keyAlias").isNullOrBlank() &&
        !keystoreProperties.getProperty("keyPassword").isNullOrBlank() &&
        resolvedReleaseKeystoreFile != null &&
        resolvedReleaseKeystoreFile.exists()

android {
    namespace = "com.timorbit.tumbuh"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.timorbit.tumbuh"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasValidReleaseSigning) {
                val storePassword = keystoreProperties.getProperty("storePassword")
                val keyAlias = keystoreProperties.getProperty("keyAlias")
                val keyPassword = keystoreProperties.getProperty("keyPassword")

                storeFile = resolvedReleaseKeystoreFile
                if (!storePassword.isNullOrBlank()) {
                    this.storePassword = storePassword
                }
                if (!keyAlias.isNullOrBlank()) {
                    this.keyAlias = keyAlias
                }
                if (!keyPassword.isNullOrBlank()) {
                    this.keyPassword = keyPassword
                }
            }
        }
    }

    buildTypes {
        release {
            // If you have configured a keystore in android/key.properties,
            // use it for release builds; otherwise fall back to debug signing.
            signingConfig =
                if (hasValidReleaseSigning) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
    }
}

flutter {
    source = "../.."
}
