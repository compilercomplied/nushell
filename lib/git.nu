
# Get the remote name of the git repo.
export def get-git-repo-name []: nothing -> string {
    if (do { git rev-parse --is-inside-work-tree } | complete).exit_code != 0 {
        error make { msg: "Current directory is not a git repository." }
    }

    git remote get-url origin
        | awk -F'[/:]' '{print $NF}'
        | sed 's/\.git//'
        | str trim
}
