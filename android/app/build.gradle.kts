import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.siddhivinayakgarments.app"
    compileSdk = flutter.compileSdkVersion

    // ✅ FIX: Use the highest NDK version required by plugins
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    signingConfigs {
        create("release") {
            val keyFile = keystoreProperties["storeFile"] as String?
            if (keyFile != null && file(keyFile).exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = file(keyFile)
                storePassword = keystoreProperties["storePassword"] as String?
            } else {
                val debugConfig = signingConfigs.getByName("debug")
                keyAlias = debugConfig.keyAlias
                keyPassword = debugConfig.keyPassword
                storeFile = debugConfig.storeFile
                storePassword = debugConfig.storePassword
            }
        }
    }

    defaultConfig {
        applicationId = "com.siddhivinayakgarments.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")

            // 🔥 FIX FOR BUILD ERROR
            isMinifyEnabled = false
            isShrinkResources = false

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // 🔥 MAIN FIX (native lib error solve)
    packaging {
        jniLibs {
            useLegacyPackaging = true
            doNotStrip.add("**/*.so")
        }
    }
}

// 🔥 NUCLEAR FIX: Disable the failing strip command entirely
tasks.configureEach {
    if (name.contains("strip") && name.contains("DebugSymbols")) {
        enabled = false
    }
}

flutter {
    source = "../.."
}