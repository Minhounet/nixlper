import org.apache.tools.ant.filters.FixCrLfFilter

plugins {
    id("distribution")
    id("com.gorylenko.gradle-git-properties") version "2.4.1"
}

group = "com.qmt"
version = "1.1.0-SNAPSHOT"

val gitId = tasks.named("generateGitProperties", com.gorylenko.GenerateGitPropertiesTask::class)
    .get().generatedProperties["git.commit.id.abbrev"] as String

val gitTime = (tasks.named("generateGitProperties", com.gorylenko.GenerateGitPropertiesTask::class)
    .get().generatedProperties["git.commit.time"] as String).substring(0, 10)

tasks.distZip {
    buildContent()
}

tasks.distTar {
    buildContent()
}

fun AbstractArchiveTask.buildContent() {
    into("/") {
        from("src/main/bash/nixlper.sh") {
            setUnixMode()
        }
        from("src/main/template/version.template") {
            filter { it.replace("\${project.name}", project.name) }
            filter { it.replace("\${project.version}", project.version.toString()) }
            filter { it.replace("\${VERSION_SHA}", gitId) }
            filter { it.replace("\${VERSION_TIME}", gitTime) }
            setUnixMode()
            rename { _ -> "version" }
        }
    }
    into("/help") {
        setUnixMode()
        from("src/main/help")
    }
}

fun CopySpec.setUnixMode() {
    dos2Unix()
    set755Mode()
}

fun CopySpec.dos2Unix() {
    filter(FixCrLfFilter::class, "eol" to FixCrLfFilter.CrLf.newInstance("unix"))
}

fun CopySpec.set755Mode() {
    fileMode = 493 // 755 in octal
}
