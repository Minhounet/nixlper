# NIXLPER

This is my personnal helper in Unix environment. I took the philosophy from [Total commander](https://www.ghisler.com/accueil.htm) and tried to apply it in Unix.

## Table of Contents

- [Project Title](#nixlper)
- [Description](#description)
- [Features](#features)
- [Installation](#installation)
- [License](#license)

## Description

The goal of the bash project is to provide useful Unix commands for various purpose. It takes the philosophy from [Total commander](https://www.ghisler.com/accueil.htm) 
and this is why it contains a lots of key shortcuts

## Prerequisites

### Java

This project is built with [Gradle](#gradle) using [JDK 20](https://www.oracle.com/java/technologies/javase/jdk20-archive-downloads.html).

### Gradle

This project is built using [Gradle](https://gradle.org/releases/) 8.4 but you can go for the latest version.

## Build

Perform the following command in the project:
```bash
gradle clean build
```
Build result should be like the screenshot below:

![gradle_build.png](documentation/gradle_build.png)

Resulting archives lays in build/distributions folder after Gradle command.
- build/distributions/nixlper-<version>.tar
- build/distributions/nixlper-<version>.zip

## Installation

### Standard installation steps

- Put the archive (zip or tar) on any server in the folder you want to install it (for instance **/opt/nixlper**).
- Unpack it using the "unzip" command or "tar -xf" command.
- Then run ./nixlper-<version>.sh install

```bash
mkdir -p /opt/nixlper
# copy archive, /tmp is example
cp /tmp/nixlper*zip /opt/nixlper
cd /opt/nixlper
unzip nixlper*.zip
./nixlper.sh install
```

Your .bashrc file will be updated and nixlper will be ready to be used for next login.

Now you are done, but if you don't use Gradle you can follow steps from [next chapter](#installation-steps-without-gradle-build).
Otherwise, please see existing [features](#features).

### Installation steps without Gradle build

Gradle is not performing a lot of tasks apart from creating an archive including the version although it is recommended 
to use. If you are too lazy to use Gradle you can simply perform the actions listed below:

Copy the file [src/main/bash/nixlper.sh](src/main/bash/nixlper.sh) in a dedicated location then source it. 
Below is an example of installation steps:

```bash
mkdir -p /opt/nixlper
cp nixlper.sh /opt/nixlper
cd /opt/nixlper
./nixlper.sh install
```
## Features

### Bookmarks
`CTRL + X then D`: display existing bookrmarks
`CTRL + X then B`: add or remote existing bookmark for **current** folder

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
