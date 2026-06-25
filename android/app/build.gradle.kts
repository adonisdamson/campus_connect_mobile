plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firebase Google Services (Auth / Google sign-in / messaging, project
// campus-connect-84893) is applied ONLY when a google-services.json is present.
// The file is gitignored, so release CI builds without it; Firebase initialises
// lazily via initFirebaseSafe() and those features stay off when absent.
if (file("src/user/google-services.json").exists() || file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
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
