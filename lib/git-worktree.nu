use git_lib.nu [git-default-branch-candidates]

export def git-current-branch [] {
  ^git branch --show-current | str trim
}

export def git-current-worktree-path [] {
  ^git rev-parse --show-toplevel | str trim
}

export def git-primary-worktree-path [] {
  ^git rev-parse --path-format=absolute --git-common-dir
    | str trim
    | path dirname
}

export def git-feature-worktree-root [] {
  let primary_path = (git-primary-worktree-path)
  let repo_name = ($primary_path | path basename)
  $nu.home-dir | path join "code" ".worktrees" $repo_name
}

export def git-feature-worktree-path [
  branch_name: string
] {
  (git-feature-worktree-root) | path join $branch_name
}

export def git-worktree-branches [] {
  ^git worktree list --porcelain
    | lines
    | where { |line| $line | str starts-with "branch refs/heads/" }
    | each { |line| $line | str replace "branch refs/heads/" "" }
}

export def git-feature-branches [] {
  let protected_branches = (git-default-branch-candidates)

  ^git branch --list --format='%(refname:short)'
    | lines --skip-empty
    | each { |it| $it | str trim }
    | where { |it| ($it != "") and ($it not-in $protected_branches) }
}

export def git-update-main-worktree [
  main_branch: string
] {
  let primary_path = (git-primary-worktree-path)
  ^git -C $primary_path checkout $main_branch
  ^git -C $primary_path pull
}

export def git-create-feature-worktree [
  branch_name: string
  main_branch: string
] {
  let primary_path = (git-primary-worktree-path)
  let worktree_path = (git-feature-worktree-path $branch_name)

  if ($worktree_path | path exists) {
    error make { msg: $"Worktree path already exists: ($worktree_path)" }
  }

  mkdir ($worktree_path | path dirname)
  git-update-main-worktree $main_branch
  ^git -C $primary_path worktree add $worktree_path -b $branch_name $main_branch
  $worktree_path
}

export def git-open-feature-worktree [
  branch_name: string
  main_branch: string
] {
  let primary_path = (git-primary-worktree-path)
  let worktree_path = (git-feature-worktree-path $branch_name)

  if ($worktree_path | path exists) {
    return $worktree_path
  }

  mkdir ($worktree_path | path dirname)

  if ($branch_name in (git-feature-branches)) {
    ^git -C $primary_path worktree add $worktree_path $branch_name
    return $worktree_path
  }

  git-create-feature-worktree $branch_name $main_branch
}
