// Top-level build file where you can add configuration options common to all sub-projects/modules.
//
// Plugins and repositories are managed in settings.gradle.kts.
// This file can be used for other global configurations.

// Redirect the build output to the root of the Flutter project.
rootProject.buildDir = rootProject.file("../build")
subprojects {
    project.buildDir = rootProject.file("${rootProject.buildDir}/${project.name}")
}

// Ensure that the subproject ':app' is evaluated before any other subproject.
subprojects {
    evaluationDependsOn(":app")
}

// Task to clean the root build directory.
tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}