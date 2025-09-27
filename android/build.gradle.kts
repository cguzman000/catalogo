import org.gradle.api.tasks.compile.JavaCompile

allprojects {
    repositories {
        // Repositories for all projects
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get() // Redirect the build output to the root build/ directory
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // Redirect subproject build outputs
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // All subprojects must be evaluated after the app module.
    project.evaluationDependsOn(":app")

    // Force Java 11 compatibility for all subprojects (app and plugins)
    project.tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_11.toString()
        targetCompatibility = JavaVersion.VERSION_11.toString()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
