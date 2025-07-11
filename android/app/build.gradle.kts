// android/app/build.gradle.kts
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.biolab.checksheet"
    compileSdk = 36 // หรือเวอร์ชันที่สูงกว่าที่คุณใช้
    ndkVersion = "28.1.13356709" // <<< เพิ่มบรรทัดนี้ (ถ้าจำเป็น)

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.biolab.checksheet"
        minSdk = 21 // Workmanager requires minSdkVersion 21 or higher
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// CRUCIAL FIX: Define kotlin_version here
val kotlin_version = "1.9.0" // <<< NEW: Define kotlin_version (use your actual Kotlin version if different)

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:$kotlin_version")
    implementation("androidx.multidex:multidex:2.0.1")
    // ... (dependencies อื่นๆ ที่มีอยู่แล้ว - ตรวจสอบว่าใช้ syntax แบบ Kotlin DSL) ...
}

flutter {
    source = "../.."
}