plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 카카오 로그인 REST API 키 설정
val kakaoRestApiKey = "91ca6e030c0d5187153efb8bf246508c"

android {
    namespace = "com.littlebank.littlebank_prod"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
        freeCompilerArgs = listOf("-Xjvm-default=all")
    }

    sourceSets {
        getByName("main") {
            manifest.srcFile("src/main/AndroidManifest.xml")
            java.srcDirs("src/main/kotlin")
            res.srcDirs("src/main/res")
        }
    }

    defaultConfig {
        applicationId = "com.littlebank.littlebank_prod"
        minSdk = 24
        targetSdk = 35
        versionCode = 18
        versionName = "1.1.7"
        
        // 카카오 로그인 REST API 키를 매니페스트에 적용
        manifestPlaceholders["REST_API_KEY"] = kakaoRestApiKey
        // 네이버 로그인 스킴 설정 (strings.xml의 naver_login_scheme 값을 사용하도록 변경)
        manifestPlaceholders["naverLoginScheme"] = "@string/naver_login_scheme"
    }

    signingConfigs {
        create("release") {
            storeFile = file("key.jks")
            storePassword = "121212"
            keyAlias = "key"
            keyPassword = "121212"
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
        }
        getByName("debug") {
            isDebuggable = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.22")
    // Java 8+ API desugaring 의존성 추가
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // AndroidX Core 의존성 - 시스템 UI 제어를 위해 필요
    implementation("androidx.core:core-ktx:1.12.0")
    // 네이버 로그인 SDK 의존성 추가
    implementation("com.navercorp.nid:oauth:5.9.1")
}
