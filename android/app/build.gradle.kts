plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.smart_kangaroo_mother_care"
    compileSdk = 34
    ndkVersion = flutter.ndkVersion


    compileOptions {
        // FIX 1: Enable Core Library Desugaring
        isCoreLibraryDesugaringEnabled = true

        // FIX 2: Set compilation to Java 1.8 for desugaring compatibility
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        // Match the JVM target to the Java compatibility version (1.8)
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        applicationId = "com.example.smart_kangaroo_mother_care"
        minSdk = flutter.minSdkVersion
        targetSdk = 34 // Line 40
        compileSdk = 34 // Line 41
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// FIX 3: Add the desugaring dependency
dependencies {
    // This library is required to "desugar" modern Java APIs (like java.time)
    // so they work on older Android devices.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
