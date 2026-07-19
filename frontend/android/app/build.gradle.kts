plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle eklentisi Android ve Kotlin eklentilerinden sonra uygulanır.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.team120.maki.maki_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Üretim paket kimliği Sprint 3 mağaza kaydında kesinleştirilecek.
        applicationId = "com.team120.maki.maki_app"
        // SDK ve sürüm değerleri Flutter yapılandırmasından alınır.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Üretim imzası Sprint 3 kapsamındadır; şimdilik yalnızca geliştirme anahtarı kullanılır.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
