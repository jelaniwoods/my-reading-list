import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

val application = Properties().apply {
    rootProject.file("Generated/application.properties").reader(Charsets.UTF_8).use { load(it) }
}

android {
    namespace = "com.firstdraft.foundation"
    compileSdk = 36
    buildToolsVersion = "36.0.0"

    defaultConfig {
        applicationId = application.getProperty("applicationId")
        minSdk = 28
        targetSdk = 36
        versionCode = application.getProperty("versionCode").toInt()
        versionName = application.getProperty("versionName")
        manifestPlaceholders["foundationPlanSha256"] = application.getProperty("foundationPlanSha256")
        buildConfigField("String", "FOUNDATION_PLAN_SHA256", "\"${application.getProperty("foundationPlanSha256")}\"")
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    lint {
        warningsAsErrors = true
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

dependencies {
    implementation("dev.hotwire:core:1.3.1")
    implementation("dev.hotwire:navigation-fragments:1.3.1")
    implementation("com.google.android.material:material:1.14.0")
    implementation("androidx.constraintlayout:constraintlayout:2.2.2")
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test:core:1.7.0")
    androidTestImplementation("androidx.test:runner:1.7.0")
    androidTestImplementation("androidx.test.ext:junit:1.3.0")
}
