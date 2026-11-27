import java.util.Properties
import java.io.FileInputStream
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

// android/app/build.gradle.kts
plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}


android {
    namespace = "com.biolab.checksheet"
    compileSdk = 36 // หรือเวอร์ชันที่สูงกว่าที่คุณใช้
    ndkVersion = "28.2.13676358" // <<< อัปเดตให้ตรงกับ Flutter 3.50 และ plugins


    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.biolab.checksheet"
        minSdk = flutter.minSdkVersion // Workmanager requires minSdkVersion 21 or higher
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

// CRUCIAL FIX: Define kotlin_version here
val kotlin_version = "2.4.20" // <<< NEW: Define kotlin_version (use your actual Kotlin version if different)

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:$kotlin_version")
    implementation("androidx.multidex:multidex:2.0.1")
    // ... (dependencies อื่นๆ ที่มีอยู่แล้ว - ตรวจสอบว่าใช้ syntax แบบ Kotlin DSL) ...
}

flutter {
    source = "../.."
}
