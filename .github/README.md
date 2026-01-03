# GitHub Actions

This directory contains GitHub Actions workflows for automating repository tasks.

## Workflows

### Auto Delete Merged Branches

**File:** `workflows/auto-delete-merged-branches.yml`

**Purpose:** Automatically deletes feature branches after they are merged via pull request.

**Triggers:** When a pull request is closed and merged

**What it does:**
1. Checks if the PR was actually merged (not just closed)
2. Validates the branch is safe to delete (prevents deletion of main, master, develop, etc.)
3. Deletes the merged branch from the remote repository
4. Posts a comment on the PR confirming the deletion

**Protected Branches:**
The workflow will never delete these branches:
- `main`
- `master`
- `develop` / `development`
- Any branch starting with `release/`

**Benefits:**
- Keeps the repository clean by removing stale branches
- Reduces manual cleanup work
- Prevents branch clutter over time

**Permissions Required:**
- `contents: write` - To delete branches

## Testing

To test the workflow:
1. Create a test branch
2. Make a small change
3. Create a pull request
4. Merge the pull request
5. Check that the branch is automatically deleted
