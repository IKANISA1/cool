import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ═══════════════════════════════════════════════════════════
// RELEASE SIGNING CONFIGURATION
// Create android/key.properties with your keystore details
// ═══════════════════════════════════════════════════════════
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.easymo.mobility_app"
    compileSdk = 36  // Required by plugins (geolocator, nfc_manager, etc.)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // ═══════════════════════════════════════════════════════════
    // SIGNING CONFIGS
    // ═══════════════════════════════════════════════════════════
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    defaultConfig {
        applicationId = "com.easymo.mobility_app"
        minSdk = flutter.minSdkVersion   // Android 5.0+ (Lollipop) for wide compatibility
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Note: ndk.abiFilters removed - use flutter build apk --release (without --split-per-abi)
        // or let splits handle ABI filtering when using --split-per-abi
    }

    buildTypes {
        release {
            // Use release signing if key.properties exists, otherwise fall back to debug
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
