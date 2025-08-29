import java.util.Properties
import java.io.FileInputStream
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}




android {
    val localProperties = Properties()
    localProperties.load(FileInputStream(rootProject.file("local.properties")))

    namespace = "org.fossindia.totp"

    signingConfigs {
        create("release") {
            storeFile = file(localProperties.getProperty("SIGNING_KEYSTORE_PATH"))
            storePassword = localProperties.getProperty("SIGNING_STORE_PASSWORD")
            keyAlias = localProperties.getProperty("SIGNING_KEY_ALIAS")
            keyPassword = localProperties.getProperty("SIGNING_KEY_PASSWORD")
        }
    }
    compileSdk = 36
    ndkVersion = "29.0.13846066"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_21.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "org.fossindia.totp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
