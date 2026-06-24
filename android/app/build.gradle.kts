plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // NOTE: Firebase/Google-services is intentionally NOT applied yet. Re-add
    // `id("com.google.gms.google-services")` + per-flavor google-services.json
    // once a Campus Connect Firebase project is configured.
}

android {
    // namespace must match the Kotlin package of MainActivity.kt
    namespace = "com.campusconnect.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.campusconnect.user"
        // API 23+ required for AES_GCM cipher in flutter_secure_storage
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // One universal APK, but only real-device ABIs (drops the x86_64 emulator
        // slice). Covers every modern arm64 phone plus older armeabi-v7a devices,
        // and is roughly a third smaller than a full universal build.
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a")
        }
    }

    flavorDimensions += "app"
    productFlavors {
        create("user") {
            dimension = "app"
            applicationId = "com.campusconnect.user"
            resValue("string", "app_name", "Campus Connect")
        }
        create("partner") {
            dimension = "app"
            applicationId = "com.campusconnect.partner"
            resValue("string", "app_name", "Campus Connect Partner")
        }
        create("admin") {
            dimension = "app"
            applicationId = "com.campusconnect.admin"
            resValue("string", "app_name", "Campus Connect Admin")
        }
    }

    signingConfigs {
        create("release") {
            storeFile = file("keystore.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
            keyAlias     = System.getenv("KEYSTORE_ALIAS")    ?: "campusconnect"
            keyPassword  = System.getenv("KEY_PASSWORD")      ?: ""
        }
    }

    buildTypes {
        release {
            signingConfig = if (file("keystore.jks").exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
