# NIXLPER

This is my personnal helper in Unix environment. I took the philosophy from [Total commander](https://www.ghisler.com/accueil.htm) and tried to apply it in Unix.

## Table of Contents

- [Description](#description)
- [Prerequisites for sh build](#prerequisites-for-sh-build)
- [Prerequisites when using Gradle build](#prerequisites-when-using-gradle-build)
  - [Java (mandatory)](#java-mandatory)
  - [Gradle (optional)](#gradle-optional)
- [Build](#build)
  - [Build with sh](#build-with-sh)
  - [Build with Gradle wrapper](#build-with-gradle-wrapper)
  - [Build with local Gradle installation](#build-with-local-gradle-installation)
- [Installation](#installation)
  - [Standard installation steps](#standard-installation-steps)
  - [Installation steps without Gradle build](#installation-steps-without-gradle-build)
- [Features](#features)
  - [Bookmarks](#bookmarks)
  - [Files and folders](#files-and-folders)
  - [Processes](#processes)
  - [Users](#users)
  - [Navigation](#navigation)
- [License](#license)

## Description

The goal of the bash project is to provide useful Unix commands for various purpose. It takes the philosophy from [Total commander](https://www.ghisler.com/accueil.htm) 
and this is why it contains a lots of key shortcuts

## Prerequisites for sh build
You need a bash command line, I personally use [Git bash](https://git-scm.com/downloads). 

## Prerequisites when using Gradle build
You may use Gradle if you don't have a bash command line for example, this may be a little overkill but it works :).

### Java (mandatory)

This project is built with [Gradle](#gradle) using [JDK 20](https://www.oracle.com/java/technologies/javase/jdk20-archive-downloads.html).

### Gradle (optional)

This project is built using [Gradle](https://gradle.org/releases/) 8.4, but you can go for the latest version. If you want to avoid Gradle
installation you build the project using the [Gradle wrapper](#build-with-gradle-wrapper).

## Build
You can use one of the build methods below:
- sh build
- Gradle build
- Gradle wrapper build

### Build with sh

The sh command is simple and straightforward.
```bash
# Execute the command
./build.sh
```

### Build with Gradle wrapper
Perform the following command in the project:
```bash
./gradlew clean build
```
Build result should be like the screenshot below:

![gradle_build.png](documentation/gradle_build.png)

Resulting archives lays in build/distributions folder after Gradle command.
- build/distributions/nixlper-<version>.tar
- build/distributions/nixlper-<version>.zip

## Build with local Gradle installation

If you have Gradle installed on your computer, you can perform the following command in the project:
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

- `CTRL + X then D`: display existing bookmarks
- `CTRL + X then B`: add or remote existing bookmark for **current** folder

### Files and folders

- `cdf FILEPATH`: Go the folder of the file


- `c`: mark current folder, use `gc` to go this folder from any place
- `cf FILEPATH` : mark file as current, use `gcf` to open it in vim from any place.


- `CTRL + X then E`: display a safe rm command such as `rm -i -rf /tmp/qmt/anyfolder && cd..` to quickly delete current folder and to avoid `rm -rf *` in your bash history.
- `CTRL + X then R`: display a safe rm command such as `rm -i -rf /tmp/qmt/anyfolder/* ` to quickly delete current folder contents and to avoid `rm -rf *` in your bash history.

### Processes

- `ik`: call interactive kill to kill by pattern or by port

### Users

- `sucd USER`: perform a su - USER and stay in current folder

### Navigation

- `CTRL + X THEN U`: perform a "cd .."
- `CTRL + X THEN N`: display an interactive way to navigate to subfolders and to open files with alias/copy-paste. Navigation
can use tree or flat mode. "tree" is the default value.

See ```export NIXLPER_NAVIGATE_MODE=tree``` in ~/.bashrc.

### Display help

- `CTRL + X then H`: give the ability to search help per topic

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
