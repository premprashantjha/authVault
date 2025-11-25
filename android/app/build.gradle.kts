plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.authenticator"
    // mobile_scanner 7.x requires compileSdk 36
    compileSdk = 36
    ndkVersion = "29.0.14206865"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.authenticator"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
    // mobile_scanner 7.x requires minSdk 23 or higher
    minSdk = 23
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Load keystore from environment variables or fallback to local file
            val keystoreFile = System.getenv("AUTHENTICATOR_KEYSTORE_FILE") ?: "release.keystore"
            
            // Always treat as relative to android/app/ directory (where this build.gradle.kts is)
            storeFile = file(keystoreFile)
            storePassword = System.getenv("AUTHENTICATOR_KEYSTORE_PASSWORD")
            keyAlias = System.getenv("AUTHENTICATOR_KEY_ALIAS") ?: "release"
            keyPassword = System.getenv("AUTHENTICATOR_KEY_PASSWORD")
        }
    }

    buildTypes {
        release {
            // Use release signing configuration
            signingConfig = signingConfigs.getByName("release")

            // Enable code shrinking and resource shrinking to reduce APK size.
            // R8 will be used to minify and optimize the bytecode.
            isMinifyEnabled = true
            isShrinkResources = true

            // Use the Android default optimized proguard file plus our rules.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                file("proguard-rules.pro")
            )
        }
    }

    // Disabled ABI splits to generate single universal APK for better Flutter compatibility
    // splits {
    //     abi {
    //         isEnable = true
    //         reset()
    //         include("armeabi-v7a", "arm64-v8a", "x86", "x86_64")
    //         isUniversalApk = true  // Enable universal APK for Flutter detection
    //     }
    // }

    // Packaging options - exclude some unnecessary metadata to shave bytes.
    packagingOptions {
        resources {
            excludes += setOf("META-INF/*.kotlin_module", "META-INF/LICENSE", "META-INF/LICENSE.txt", "META-INF/NOTICE")
        }
    }
}

flutter {
    source = "../.."
}
