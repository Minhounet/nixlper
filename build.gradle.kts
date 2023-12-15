plugins {
    id("distribution")
}

group = "com.qmt"
version = "1.0-SNAPSHOT"

tasks.distZip {
    buildContent()
}

tasks.distTar {
    buildContent()
}

fun AbstractArchiveTask.buildContent() {
    into("/") {
        from("src/main/bash/nixlper.sh")
    }
}