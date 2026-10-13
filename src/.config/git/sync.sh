#!/bin/bash

# git sync: fetch the main remote, fast-forward local branches that are only
# behind it, and delete branches whose remote branch is gone after being
# merged into the default branch. A branch checked out in a worktree is
# fast-forwarded inside that worktree so its index and files move with it.

set -u

warn() {
    printf 'warning: %s\n' "$*" >&2
}

die() {
    printf 'fatal: %s\n' "$*" >&2
    exit 1
}

# Prints a directory as an absolute path with symlinks resolved so paths
# reported from different worktrees can be compared as strings.
physical_dir() {
    [ -n "$1" ] && (cd "$1" 2>/dev/null && pwd -P)
}

# Runs git in worktree $1. Variables that locate the repository, such as
# GIT_DIR and GIT_INDEX_FILE, may be exported by the alias for the current
# worktree, so they are dropped to let -C find the other worktree's own.
# Settings passed with `git -c` are kept.
in_worktree() {
    local wt=$1
    shift
    (
        unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR \
            GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES \
            GIT_IMPLICIT_WORK_TREE GIT_PREFIX
        git -C "$wt" "$@"
    )
}

# Prints, NUL-terminated, the paths of worktrees that have ref $1 checked out
# and succeeds only if there is at least one. NUL-terminated porcelain output
# keeps paths with spaces or newlines intact.
worktrees_of() {
    local line wt='' found=1
    while IFS= read -r -d '' line; do
        case $line in
        "worktree "*) wt=${line#worktree } ;;
        "branch $1")
            printf '%s\0' "$wt"
            found=0
            ;;
        esac
    done < <(git worktree list --porcelain -z)
    return "$found"
}

# Succeeds if worktree $1 still has ref $2 checked out and belongs to this
# repository. The path recorded by `git worktree list` may have been removed
# and reused for something else.
verify_worktree() {
    local head common
    head=$(in_worktree "$1" symbolic-ref --quiet HEAD 2>/dev/null) || return 1
    common=$(in_worktree "$1" rev-parse --git-common-dir 2>/dev/null) || return 1
    [ "$head" = "$2" ] && [ "$(cd "$1" && physical_dir "$common")" = "$common_dir" ]
}

# Prints "<ahead> <behind>" of $1 relative to $2.
commit_difference() {
    local counts
    counts=$(git rev-list --left-right --count "$1...$2" --) || return 1
    printf '%s %s' "${counts%%[[:space:]]*}" "${counts##*[[:space:]]}"
}

fast_forward() {
    local branch=$1 full=refs/heads/$1 target=$2 old new wt err i
    local worktrees=()
    old=$(git rev-parse "$full") || return 1
    new=$(git rev-parse "$target") || return 1
    while IFS= read -r -d '' wt; do
        worktrees+=("$wt")
    done < <(worktrees_of "$full")

    if [ "${#worktrees[@]}" -eq 0 ]; then
        # Unlike update-ref, `branch -f` refuses a branch that a worktree is
        # rebasing or bisecting.
        if ! err=$(git branch --force "$branch" "$new" 2>&1); then
            warn "couldn't fast-forward '$branch': $err"
            return 1
        fi
        echo "Updated branch $branch (was ${old:0:7})."
        return 0
    fi

    for wt in "${worktrees[@]}"; do
        if ! verify_worktree "$wt" "$full"; then
            warn "couldn't fast-forward '$branch': worktree '$wt' no longer has it checked out (see \`git worktree prune\`)"
            return 1
        fi
    done
    # A branch checked out in several worktrees (worktree add --force) shares
    # one ref, so after the first worktree moves it the others only need
    # their index and files updated. Check them all first so a failure leaves
    # every worktree untouched.
    if [ "${#worktrees[@]}" -gt 1 ]; then
        for wt in "${worktrees[@]}"; do
            # Refresh first so files whose stat data alone changed are not
            # reported as "not uptodate".
            in_worktree "$wt" update-index -q --refresh >/dev/null
            if ! err=$(in_worktree "$wt" read-tree --dry-run -m -u "$old" "$new" 2>&1); then
                warn "couldn't fast-forward '$branch' in worktree '$wt': $err"
                return 1
            fi
        done
    fi
    if ! err=$(in_worktree "${worktrees[0]}" merge --ff-only --quiet "$new" 2>&1 >/dev/null); then
        warn "couldn't fast-forward '$branch' in worktree '${worktrees[0]}': $err"
        return 1
    fi
    for ((i = 1; i < ${#worktrees[@]}; i++)); do
        if ! err=$(in_worktree "${worktrees[i]}" read-tree -m -u "$old" "$new" 2>&1); then
            warn "couldn't update worktree '${worktrees[i]}' for '$branch': $err"
            warn "retry with: git -C '${worktrees[i]}' read-tree -m -u $old $new"
            return 1
        fi
    done
    echo "Updated branch $branch (was ${old:0:7})."
}

delete_merged() {
    local branch=$1 full=refs/heads/$1 diff old wt here=''
    if ! diff=$(commit_difference "$full" "$default_ref"); then
        warn "couldn't compare '$branch' against '$default_ref'"
        return 1
    fi
    if [ "${diff% *}" -ne 0 ]; then
        warn "'$branch' was deleted on $remote, but appears not merged into '$default'"
        return 0
    fi
    old=$(git rev-parse "$full") || return 1
    while IFS= read -r -d '' wt; do
        # Switching another worktree away from its branch would surprise
        # whoever is working there, so only the current one is switched.
        if [ "$(physical_dir "$(in_worktree "$wt" rev-parse --absolute-git-dir 2>/dev/null)")" != "$git_dir" ]; then
            warn "'$branch' was deleted on $remote, but is checked out in worktree '$wt'"
            return 0
        fi
        here=1
    done < <(worktrees_of "$full")
    if [ -n "$here" ]; then
        # A missing local default branch is created from the main remote
        # explicitly, since switch's guessing fails when several remotes have
        # it. A default branch checked out elsewhere cannot be checked out
        # here too, so the worktree is detached at the remote one instead.
        if ! git show-ref --verify --quiet "refs/heads/$default"; then
            git switch --quiet --create "$default" --track "$default_ref"
        elif worktrees_of "refs/heads/$default" >/dev/null; then
            git switch --quiet --detach "$default_ref" &&
                echo "Switched to detached HEAD at $remote/$default."
        else
            git switch --quiet "$default"
        fi || {
            warn "couldn't switch away from '$branch'"
            return 1
        }
    fi
    if ! git branch -D "$branch" >/dev/null; then
        warn "couldn't delete '$branch'"
        return 1
    fi
    echo "Deleted branch $branch (was ${old:0:7})."
}

# Mirrors gh-sync's processBranch: decide which remote ref the branch follows,
# then fast-forward it, warn about unpushed commits, or treat it as gone.
# $2-$4 are the branch's %(upstream:remotename), %(upstream) and
# %(upstream:track).
sync_branch() {
    local branch=$1 tracked=$2 upstream=$3 track=$4 diff
    local target=refs/remotes/$remote/$1
    if [ "$tracked" = "$remote" ]; then
        if [ "$track" = "[gone]" ]; then
            delete_merged "$branch"
            return
        fi
        if [ -z "$upstream" ]; then
            # The upstream is empty when branch.<name>.merge is missing or
            # the fetch refspec does not map it (e.g. a single-branch clone).
            # A same-named remote ref suggests the former.
            if git show-ref --verify --quiet "$target"; then
                warn "'$branch' upstream config is broken; skipping"
            fi
            return 0
        fi
        target=$upstream
    elif ! git show-ref --verify --quiet "$target"; then
        return 0
    fi

    if ! diff=$(commit_difference "refs/heads/$branch" "$target"); then
        warn "couldn't compare '$branch' against '$target'"
        return 1
    fi
    if [ "${diff% *}" -ne 0 ]; then
        warn "'$branch' seems to contain unpushed commits"
    elif [ "${diff#* }" -ne 0 ]; then
        fast_forward "$branch" "$target"
    fi
}

git rev-parse --git-dir >/dev/null 2>&1 || die "Not a git repository"
git worktree list --porcelain -z >/dev/null 2>&1 ||
    die "\`git worktree list --porcelain -z\` failed (requires git 2.36 or later)"
git_dir=$(physical_dir "$(git rev-parse --absolute-git-dir)")
common_dir=$(physical_dir "$(git rev-parse --git-common-dir)")

remotes=$(git remote)
[ -n "$remotes" ] || die "no git remotes found"
remote=
for candidate in upstream github origin; do
    if printf '%s\n' "$remotes" | grep -qxF -- "$candidate"; then
        remote=$candidate
        break
    fi
done
[ -n "$remote" ] || remote=$(printf '%s\n' "$remotes" | head -n 1)

# Fetch before resolving the default branch so a remote that has never been
# fetched still has refs/remotes/<remote>/main or master to fall back on.
git fetch --prune --quiet "$remote" || die "Failed to fetch from $remote"

# <remote>/HEAD is not updated by fetch, so it can still point at a branch
# that was renamed and pruned on the remote.
default=
head_ref=$(git symbolic-ref --quiet "refs/remotes/$remote/HEAD" 2>/dev/null)
if [ "${head_ref#refs/remotes/"$remote"/}" != "$head_ref" ] &&
    git show-ref --verify --quiet "$head_ref"; then
    default=${head_ref#refs/remotes/"$remote"/}
elif git show-ref --verify --quiet "refs/remotes/$remote/main"; then
    default=main
elif git show-ref --verify --quiet "refs/remotes/$remote/master"; then
    default=master
else
    die "could not determine default branch for $remote; set it with \`git remote set-head $remote --auto\`"
fi
default_ref=refs/remotes/$remote/$default

# ':' cannot appear in ref or remote names, so it safely separates fields.
failed=0
while IFS=: read -r branch tracked upstream track <&3; do
    sync_branch "$branch" "$tracked" "$upstream" "$track" || failed=1
done 3< <(git for-each-ref \
    --format='%(refname:lstrip=2):%(upstream:remotename):%(upstream):%(upstream:track)' refs/heads/)
exit "$failed"
