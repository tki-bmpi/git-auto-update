echo ""
echo "   _______ __     ___         __           __  __          __      __     "
echo "  / ____(_) /_   /   | __  __/ /_____     / / / /___  ____/ /___ _/ /____ "
echo " / / __/ / __/  / /| |/ / / / __/ __ \   / / / / __ \/ __  / __ \`/ __/ _ \\"
echo "/ /_/ / / /_   / ___ / /_/ / /_/ /_/ /  / /_/ / /_/ / /_/ / /_/ / /_/  __/"
echo "\____/_/\__/  /_/  |_\__,_/\__/\____/   \____/ .___/\__,_/\__,_/\__/\___/ "
echo "                                            /_/                            "
echo ""


###  CONFIG – edit BASE_DIR to point at your repo folder     
BASE_DIR="/path/to/repo"

###  Discover repositories                                   
EXCLUDE_REPOS=("")                  # names to skip, e.g. ("dotfiles" "sandbox")
REPOS=()

for d in "$BASE_DIR"/*/; do
    repo_name="${d%/}"              # strip trailing /
    repo_name="${repo_name##*/}"    # folder only

    if [ -e "$d/.git" ] && [[ ! " ${EXCLUDE_REPOS[*]} " =~ " $repo_name " ]]; then
        REPOS+=("$repo_name")
    fi
done

echo "Found the following Git repositories under $BASE_DIR:"
for repo in "${REPOS[@]}"; do
    echo "⤷ $repo"
done
echo ""


###  Grace period before starting
echo "Updates start in 3 seconds – press ANY key to cancel."
read -r -n 1 -t 3 key && { echo "Start aborted."; exit 1; }

###  Process each repository
for repo in "${REPOS[@]}"; do
    REPO_PATH="$BASE_DIR/$repo"
    [ -d "$REPO_PATH/.git" ] || { echo "🙀 Skipping $repo (not a Git repo)"; continue; }

    echo ""
    echo ""
    echo "------------------------------------- $repo"
    echo ""

    cd "$REPO_PATH" || { echo "Cannot cd into $REPO_PATH"; continue; }

    ### 1. Fetch
    echo "⏬ Fetching changes..."
    git fetch --prune

    ### 2. Delete local branches whose upstream is gone
    echo "🧹 Deleting obsolete local branches..."
    git branch -vv | awk '/: gone]/{print $1}' | xargs --no-run-if-empty git branch -D

    ### 3. Fast-forward branches strictly behind their remote
    echo "⏩ Fast-forwarding local branches..."
    git for-each-ref --format='%(refname:short)' refs/heads | while read -r branch; do
        remote_ref="origin/$branch"
        if ! git show-ref --quiet "refs/remotes/$remote_ref"; then
            echo "   ℹ️  $branch → no remote twin (skipped)"
            continue
        fi

        local_sha=$(git rev-parse "$branch")
        remote_sha=$(git rev-parse "$remote_ref")

        if [ "$local_sha" = "$remote_sha" ]; then
            echo "   ✅ $branch is up-to-date"
        elif git merge-base --is-ancestor "$branch" "$remote_ref"; then
            git update-ref "refs/heads/$branch" "$remote_sha"
            echo "   ✅ $branch fast-forwarded"
        else
            echo "   ⚠️  $branch diverged (manual review needed)"
        fi
    done
    cd "$BASE_DIR" || exit 1
done

echo "\n🚀 All repositories synchronized!"
