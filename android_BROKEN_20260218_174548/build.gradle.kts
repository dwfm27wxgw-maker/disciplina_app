@"
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.register("clean", Delete::class) {
    delete(rootProject.layout.buildDirectory)
}
"@ | Set-Content -Path .\build.gradle.kts -Encoding UTF8