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

## Installation

Copy the file [src/main/bash/nixlper.sh](src/main/bash/nixlper.sh) in a dedicated location then source it. Below is an example of installation steps
```bash
mkdir -p /opt/nixlper
cp nixlper.sh /opt/nixlper
cd /opt/nixlper
source nixlper.sh
```

## Features

### Bookmarks
`CTRL + X then D`: display existing bookrmarks
`CTRL + X then B`: add or remote existing bookmark for **current** folder

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
