cd C:\disciplina_app\android

@"
import java.util.Properties

val localProperties = Properties()
val localPropertiesFile = file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val flutterSdkPath = localProperties.getProperty("flutter.sdk")
    ?: System.getenv("FLUTTER_ROOT")
    ?: throw GradleException("Flutter SDK not found. Define flutter.sdk in android/local.properties or set FLUTTER_ROOT.")

pluginManagement {
    includeBuild("\$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
}

include(":app")
"@ | Set-Content -Path .\settings.gradle.kts -Encoding UTF8