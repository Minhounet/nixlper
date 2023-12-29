plugins {
    id("distribution")
    id("com.gorylenko.gradle-git-properties") version "2.4.1"
}

group = "com.qmt"
version = "1.0-SNAPSHOT"

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
        from("src/main/bash/nixlper.sh")
        from("src/main/template/version.template") {
            filter { it.replace("\${project.name}", project.name) }
            filter { it.replace("\${project.version}", project.version.toString()) }
            filter { it.replace("\${VERSION_SHA}", gitId) }
            filter { it.replace("\${VERSION_TIME}", gitTime) }
            // 4) Unix end of line, must be used when using replacement like above
            filter(org.apache.tools.ant.filters.FixCrLfFilter::class, "eol" to org.apache.tools.ant.filters.FixCrLfFilter.CrLf.newInstance("unix"))
            rename { _ -> "version" }
        }
    }
}
