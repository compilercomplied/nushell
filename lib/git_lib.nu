
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


export def git-default-branch-candidates [] {
  ["main" "master" "trunk"]
}

# calculate git main branch from remote and default candidates.
export def git-main-branch [
  main?: string
] {
  if ($main != null) {
    return $main
  }

  let remote_head = (try {
    ^git symbolic-ref --quiet --short refs/remotes/origin/HEAD
      | str trim
  } catch {
    null
  })

  if ($remote_head != null) and ($remote_head != "") {
    return ($remote_head | split row "/" | last)
  }

  let branches = (
    ^git branch --list --format='%(refname:short)'
      | lines
      | each { |it| $it | str trim }
      | where { |it| $it != "" }
  )

  let remote_branches = (
    ^git branch --remotes --format='%(refname:lstrip=3)'
      | lines
      | each { |it| $it | str trim }
      | where { |it| $it != "" }
  )

  for branch in (git-default-branch-candidates) {
    if ($branch in $branches) or ($branch in $remote_branches) {
      return $branch
    }
  }

  error make { msg: "Unable to infer the default branch; pass it explicitly." }
}
