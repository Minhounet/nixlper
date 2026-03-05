# NIXLPER Project Summary for Gemini

Nixlper is a personal helper tool designed for Unix environments, drawing inspiration from the Total Commander philosophy by providing numerous key shortcuts for efficient command-line operations. It's a modular bash project, with scripts located in `src/main`, which are then concatenated and packaged into a single distributable archive by a `build.sh` script. The main entry point after installation is `nixlper.sh`.

## Key Features and Functionality:

*   **Modular Architecture:** Facilitates easier development and maintenance of individual bash modules.
*   **Build Process:** Utilizes `build.sh` to create a single `.tar` archive, output to `build/distributions/`.
*   **Installation/Update:** Offers both a recommended `install.sh` script for automated installation/updates (defaulting to `/opt/nixlper` and configuring `.bashrc`) and manual options using `nixlper.sh install` or `nixlper.sh update`.
*   **Uninstallation:** A straightforward `nixlper uninstall` command is available.
*   **Core Features:**
    *   **Bookmarks:** Keyboard shortcuts (`CTRL + X then D`, `CTRL + X then B`) to manage directory bookmarks.
    *   **Files and Folders:** Commands for directory navigation (`cdf`), marking current folders/files (`c`, `cf`), copying full paths to clipboard (`cpcb`, `cpdcb`), and safe file/folder deletion (`CTRL + X then E`, `CTRL + X then R`).
    *   **Processes:** An interactive kill command (`ik`) allowing termination by pattern or port.
    *   **Users:** `sucd` command to switch users while retaining the current directory.
    *   **Navigation:** Enhanced navigation with shortcuts (`CTRL + X THEN U` for `cd ..`, `CTRL + X THEN N` for interactive subfolder/file navigation, with a toggleable `NIXLPER_NAVIGATE_MODE` for tree/flat view and permissions display) and a `fan` command for pattern-based file searching.
    *   **Macros:** Functionality to record (`CTRL + P`) and play back (`CTRL + X, CTRL + X`) command sequences.
    *   **Help System:** An interactive help search accessible via `CTRL + X then H`.
    *   **Version Information:** Display of the Nixlper logo, version, and Git SHA with `CTRL + X then V`.
*   **License:** The project is distributed under the MIT License.