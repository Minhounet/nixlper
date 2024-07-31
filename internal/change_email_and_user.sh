#!/bin/bash

# Was used to anonymize all mail in this project.

# Ensure script exits if a command fails
set -e

# Current repository directory
REPO_DIR="https://github.com/Minhounet/nixlper"


# Clone the repository as a mirror
git clone "$REPO_DIR" nixlper

# Change to the temporary directory
cd nixlper

# New author name and email
NEW_AUTHOR_NAME="Minhounet"
NEW_AUTHOR_EMAIL="Minhounet@users.noreply.github.com"

# Filter the repository to change author and committer info
git filter-branch --env-filter "
export GIT_AUTHOR_NAME='$NEW_AUTHOR_NAME'
export GIT_AUTHOR_EMAIL='$NEW_AUTHOR_EMAIL'
export GIT_COMMITTER_NAME='$NEW_AUTHOR_NAME'
export GIT_COMMITTER_EMAIL='$NEW_AUTHOR_EMAIL'
" --tag-name-filter cat -- --all

# Push changes back to the original repository (force push for branches)
git push --force origin

# Push tags separately
git push --force --tags origin

echo "All authors' names and emails have been rewritten."
