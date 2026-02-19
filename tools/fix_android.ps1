param([switch]$DeepClean)

$ErrorActionPreference = "Stop"

$root = "C:\disciplina_app"
$android = Join-Path $root "android"
$settingsKts = Join-Path $android "settings.gradle.kts"
$localProps  = Join-Path $android "local.properties"
$gradlew     = Join-Path $android "gradlew.bat"

Write-Host "== Disciplina Android Fix =="

if (!(Test-Path $gradlew)) { throw "No existe gradlew.bat en $android" }

if (!(Test-Path $localProps)) {
  $default = @"
sdk.dir=C:\Users\famil\AppData\Local\Android\Sdk
flutter.sdk=C:\flutter\flutter
"@
  Set-Content -Path $localProps -Value $default -Encoding UTF8
  Write-Host "local.properties creado"
} else {
  Write-Host "local.properties OK"
}

$settings = @'
println("USING settings.gradle.kts")

pluginManagement {
    val props = java.util.Properties()
    val propsFile = java.io.File(settingsDir, "local.properties")

    if (propsFile.exists()) {
        java.io.FileInputStream(propsFile).use { fis ->
            props.load(fis)
        }
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
'@

Set-Content -Path $settingsKts -Value $settings -Encoding UTF8
Write-Host "settings.gradle.kts escrito"

& $gradlew --stop | Out-Host
Remove-Item -Recurse -Force (Join-Path $android ".gradle") -ErrorAction SilentlyContinue

if ($DeepClean) {
  Remove-Item -Recurse -Force (Join-Path $android "app\build") -ErrorAction SilentlyContinue
  Remove-Item -Recurse -Force (Join-Path $root "build") -ErrorAction SilentlyContinue
}

Write-Host "Ejecutando gradlew projects..."
& $gradlew projects --info | Out-Host