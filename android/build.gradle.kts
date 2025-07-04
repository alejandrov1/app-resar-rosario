plugins {
    // Aplica plugins aquí si es necesario a nivel de raíz
}

buildscript {
    val kotlinVersion = "1.9.23" // Definición de la variable en Kotlin
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.2.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = file("../build")
subprojects {
    project.buildDir = File(rootProject.buildDir, project.name)
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}