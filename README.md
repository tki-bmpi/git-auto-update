# Git Auto Update
This script scans a defined base directory containing multiple Git repositories and:

- ⏬ Fetches updates from `origin`
- 🧹 Deletes obsolete local branches
- ⏩ Fast-forwards any local branch that is behind its remote

## 🚀 Setup
### 1. Get the script

```bash
git clone https://github.com/Zuhlek/git-auto-update.git
cd git-auto-update       # or just download git-auto-update.sh
```

### 2. Configure
Open `git-auto-update.sh` and set the root folder that holds your Git repos:

```bash
BASE_DIR="/absolute/path/to/repos"
```

## ▶️ Usage
### macOS / Linux
```bash
chmod +x git-auto-update.sh   # first time only
./git-auto-update.sh
```

### Windows (Git Bash or WSL)
```bash
bash git-auto-update.sh
```

## 🛑 What happens
The script lists every Git repo found under `BASE_DIR`. It waits 2 seconds before proceeding – press any key to cancel. It performs the following Git commands on the selected repositories:

| Step                          | Git commands used                                                                                                                                                        | What the script does                                                                                                                                              | Why it’s safe                                                                                                                                                                                                     |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1. Fetch**                  | `git fetch --prune`                                                                                                                                                      | Updates all remote refs and removes any remote branches that were deleted on the server.                                                                          | Only remote‐tracking refs are changed; your local branches are untouched.                                                                                                                                         |
| **2. List gone branches**     | `git branch -vv`<br>`awk '/: gone]/{print $1}'`                                                                                                                          | Detects local branches whose upstream was deleted on the remote.                                                                                                  | Branches are only *candidates* for deletion—see next step.                                                                                                                                                        |
| **3. Delete obsolete locals** | `xargs git branch -D`                                                                                                                                                    | Deletes the obsolete local branches from step 2.                                                                                                                  | These branches no longer exist upstream, so deleting them locally cannot overwrite remote history. Your commits remain in the reflog for ≈90 days, so you can still recover.                                      |
| **4. Fast-forward locals**    | `git for-each-ref --format='%(refname:short)' refs/heads` → loop<br>`git rev-parse` & `git merge-base --is-ancestor`<br>`git update-ref refs/heads/<branch> <remoteSHA>` | For every local branch that *is strictly behind* its remote twin, moves the branch pointer forward to match the remote (no merge, no rebase, no checkout needed). | **Fast-forward only:** the branch pointer is moved *iff* your local branch is an ancestor of the remote. Diverged branches (with local commits) are skipped entirely, so your work is never lost or force-pushed. |
| **5. Diverged notice**        | *echo only*                                                                                                                                                              | Prints a warning for branches that have diverged, telling you to handle them manually.                                                                            | Prevents accidental history rewrites—nothing is changed when divergence is detected.                                                                                                                              |


## 📄 License
MIT — use freely, no warranty.
