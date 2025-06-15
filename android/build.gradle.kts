// --- START OF FIX ---
// This entire buildscript block is now in correct Kotlin Script syntax.
buildscript {
    // In .kts, you define properties on the `extra` object.
    val kotlin_version by extra("1.9.23")

    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // In .kts, use parentheses for method calls.
        classpath("com.android.tools.build:gradle:8.2.0")
        // Use the kotlin_version variable we just defined.
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")
    }
}
// --- END OF FIX ---


// Your existing code starts here. Leave it as is.
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