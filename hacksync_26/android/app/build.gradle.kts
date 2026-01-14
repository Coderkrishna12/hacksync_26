plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // if using Firebase
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.hacksync_26"
    compileSdk = 34  // or 35/36 if your Flutter version expects it

    defaultConfig {
        applicationId = "com.example.hacksync_26"
        minSdk = flutter.minSdkVersion  // fixed: changed from minSdkVersion() function to minSdk property
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }

        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Modern replacement for deprecated kotlinOptions { jvmTarget = "17" }
    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

flutter {
    source = "../.."
}
