plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 카카오 로그인 REST API 키 설정
val kakaoRestApiKey = "91ca6e030c0d5187153efb8bf246508c"
// 네이버 클라이언트 ID 설정
val naverClientId = "xDoTbCTjZYNhgSkEK1K7"
// 네이버 클라이언트 시크릿 설정
val naverClientSecret = "RETtyp4ogI"
// 네이버 클라이언트 이름 설정
val naverClientName = "littlebank"

android {
    namespace = "com.example.android_design_preview"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
        freeCompilerArgs = listOf("-Xuse-k2", "-opt-in=kotlin.RequiresOptIn", "-language-version=1.9")
    }

    sourceSets {
        getByName("main") {
            manifest.srcFile("src/main/AndroidManifest.xml")
            java.srcDirs("src/main/kotlin")
            res.srcDirs("src/main/res")
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.android_design_preview"
        // You can update the following values to match your application needs.
        // For more information, see: https://docs.flutter.dev/deployment/android#reviewing-the-gradle-build-configuration.
        minSdk = 21 // 카카오 SDK는 최소 API 레벨 21이 필요합니다
        targetSdk = flutter.targetSdkVersion
        versionCode = 1
        versionName = "1.0.0"
        
        // 카카오 로그인 REST API 키를 매니페스트에 적용
        manifestPlaceholders["REST_API_KEY"] = kakaoRestApiKey
        // 네이버 클라이언트 ID를 매니페스트에 적용
        manifestPlaceholders["naverClientId"] = naverClientId
        manifestPlaceholders["naverClientSecret"] = naverClientSecret
        manifestPlaceholders["naverClientName"] = naverClientName
        manifestPlaceholders["naverLoginScheme"] = "naver$naverClientId"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.0")
}
