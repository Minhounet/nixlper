# nixlper requires bash; skip silently on ksh, dash, or any other POSIX sh
[ -n "$BASH_VERSION" ] && source /usr/share/nixlper/nixlper.sh
