allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// SOLUCIÓN: Usar rootProject.file() para crear un objeto File a partir de la ruta
rootProject.buildDir = rootProject.file("../build")
subprojects {
    project.buildDir = rootProject.file("${rootProject.buildDir}/${project.name}")
}

subprojects {
    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}