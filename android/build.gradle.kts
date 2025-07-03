// Archivo de compilación de nivel superior
allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Forzar Java 11 en TODOS los módulos del proyecto.
    // Esta es la corrección clave para eliminar las advertencias y errores de compatibilidad.
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = "11"
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}