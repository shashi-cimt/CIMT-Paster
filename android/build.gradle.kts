buildscript {
    repositories {
        google() // Google's Maven repository
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")  // Add the correct version of the plugin
        classpath("com.android.tools.build:gradle:8.1.0") // or the latest compatible version
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.22") // Ensure Kotlin plugin version is correct
        classpath("com.google.firebase:firebase-crashlytics-gradle:3.0.6") // Add this line
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }

}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
