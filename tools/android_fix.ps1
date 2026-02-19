param([switch]$DeepClean)

$ErrorActionPreference = "Stop"

$root    = "C:\disciplina_app"
$android = Join-Path $root "android"
$appDir  = Join-Path $android "app"

$settingsKts = Join-Path $android "settings.gradle.kts"
$rootGradle  = Join-Path $android "build.gradle.kts"
$appGradle   = Join-Path $appDir  "build.gradle.kts"
$gradleProps = Join-Path $android "gradle.properties"
$localProps  = Join-Path $android "local.properties"
$gradlew     = Join-Path $android "gradlew.bat"

Write-Host "== ANDROID FIX Disciplina ==" -ForegroundColor Cyan
Write-Host "root: $root" -ForegroundColor DarkGray
Write-Host "android: $android" -ForegroundColor DarkGray

if (!(Test-Path $gradlew)) { throw "No existe gradlew.bat en $android" }
if (!(Test-Path $appDir))  { throw "No existe android\app en $android" }

# local.properties (ajusta flutter.sdk si tu ruta real es otra)
if (!(Test-Path $localProps)) {
@"
sdk.dir=C:\Users\famil\AppData\Local\Android\Sdk
flutter.sdk=C:\flutter\flutter
"@ | Set-Content -Path $localProps -Encoding UTF8
  Write-Host "local.properties creado" -ForegroundColor Yellow
} else {
  Write-Host "local.properties OK" -ForegroundColor Green
}

# settings.gradle.kts (Kotlin DSL correcto)
@'
println("USING settings.gradle.kts")

pluginManagement {
    val props = java.util.Properties()
    val propsFile = java.io.File(settingsDir, "local.properties")
    if (propsFile.exists()) {
        java.io.FileInputStream(propsFile).use { fis -> props.load(fis) }
    }

    val flutterSdkPath =
        props.getProperty("flutter.sdk")
            ?: System.getenv("FLUTTER_ROOT")
            ?: throw GradleException("Flutter SDK not found. Define flutter.sdk in android/local.properties or set FLUTTER_ROOT.")

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

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
'@ | Set-Content -Path $settingsKts -Encoding UTF8
Write-Host "settings.gradle.kts OK" -ForegroundColor Green

# android/build.gradle.kts (ROOT MINIMO)
@'
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
'@ | Set-Content -Path $rootGradle -Encoding UTF8
Write-Host "android/build.gradle.kts OK" -ForegroundColor Green

# android/app/build.gradle.kts (APP CORRECTO)
@'
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.disciplina_app"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.disciplina_app"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
'@ | Set-Content -Path $appGradle -Encoding UTF8
Write-Host "android/app/build.gradle.kts OK" -ForegroundColor Green

# gradle.properties (AndroidX ON)
if (!(Test-Path $gradleProps)) {
@"
org.gradle.jvmargs=-Xmx4096m
android.useAndroidX=true
android.enableJetifier=true
"@ | Set-Content -Path $gradleProps -Encoding UTF8
  Write-Host "gradle.properties creado" -ForegroundColor Yellow
} else {
  $gp = Get-Content $gradleProps -Raw
  if ($gp -notmatch "android\.useAndroidX=true") { Add-Content $gradleProps "`nandroid.useAndroidX=true" }
  if ($gp -notmatch "android\.enableJetifier=true") { Add-Content $gradleProps "`nandroid.enableJetifier=true" }
  Write-Host "gradle.properties OK" -ForegroundColor Green
}

# Clean caches
& $gradlew --stop | Out-Host
Remove-Item -Recurse -Force (Join-Path $android ".gradle") -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force (Join-Path $android "build") -ErrorAction SilentlyContinue

if ($DeepClean) {
  Remove-Item -Recurse -Force (Join-Path $android "app\build") -ErrorAction SilentlyContinue
  Remove-Item -Recurse -Force (Join-Path $root "build") -ErrorAction SilentlyContinue
  Write-Host "DeepClean OK" -ForegroundColor Yellow
}

Write-Host "== gradlew projects ==" -ForegroundColor Cyan
Push-Location $android
& $gradlew projects --info | Out-Host
Pop-Location

Write-Host "== DONE ==" -ForegroundColor Green