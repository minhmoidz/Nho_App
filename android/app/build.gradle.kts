plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.minh.nhoapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        // GIỮ NGUYÊN JAVA 11 NHƯNG BẬT DESUGARING
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11

        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID
        applicationId = "com.minh.nhoapp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        // Cấu hình cho bản Release (Chạy khi build APK/AAB hoặc run --release)
        getByName("release") {
            // Dùng tạm key debug để test release. Khi up store nhớ đổi lại config này.
            signingConfig = signingConfigs.getByName("release")

            // BẬT NÉN CODE & TỐI ƯU RESOURCES
            isMinifyEnabled = true
            isShrinkResources = true

            // NẠP FILE RULE ĐỂ KHÔNG BỊ LỖI CRASH GSON/NOTIFICATIONS
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
    }
}

dependencies {
    // Thư viện hỗ trợ Desugaring (Quan trọng cho DateTime trên Android thấp)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // Các thư viện ML Kit (Giữ nguyên của bạn)
    implementation("com.google.mlkit:text-recognition-chinese:16.0.0")
    implementation("com.google.mlkit:text-recognition-devanagari:16.0.0")
    implementation("com.google.mlkit:text-recognition-japanese:16.0.0")
    implementation("com.google.mlkit:text-recognition-korean:16.0.0")
}

flutter {
    source = "../.."
}

configurations.all {
    resolutionStrategy {
        // Ép dùng phiên bản activity mới để tránh xung đột
        force("androidx.activity:activity:1.9.3")
    }
}

// Tắt cảnh báo Java Obsolete cho đỡ rối mắt khi build
tasks.withType<JavaCompile>().configureEach {
    options.compilerArgs.add("-Xlint:-options")
}