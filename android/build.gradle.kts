// Top-level build.gradle.kts file (usually located at the root of the project)

// 1. Configuring the buildscript block for repositories and dependencies
buildscript {
    // Defining Kotlin version (make sure this matches your setup)
    val kotlin_version = "1.7.10"

    repositories {
        google()  // Google's repository for dependencies
        mavenCentral()  // Maven central repository for dependencies
    }

    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version") // Kotlin plugin for Gradle
        classpath("com.google.gms:google-services:4.4.3") // Google services plugin
    }
}

// 2. Declaring plugins and ensuring google-services is applied correctly
plugins {
    id("com.google.gms.google-services") apply false // Apply the correct version of the plugin
}

// 3. Repositories block for subprojects
allprojects {
    repositories {
        google()  // Google's repository for dependencies
        mavenCentral()  // Maven central repository for dependencies
    }
}

// 4. Define custom build directories if needed (for multi-project builds)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 5. Ensuring the app subproject is evaluated
subprojects {
    project.evaluationDependsOn(":app")
}

// 6. Clean task for cleaning the build directory
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
