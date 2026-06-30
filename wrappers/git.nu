use ../lib/logger.nu
use ../lib/git_lib.nu [
  git-main-branch
]
use ../lib/git-worktree.nu [
  git-current-branch
  git-current-worktree-path
  git-feature-branches
  git-feature-worktree-path
  git-open-feature-worktree
  git-primary-worktree-path
  git-update-main-worktree
  git-worktree-branches
]

# Helper for feature branch completion
def "nu-complete git-features" [] {
  let worktree_branches = (git-worktree-branches)

  try {
    git-feature-branches
      | each { |branch|
          let has_worktree = ($branch in $worktree_branches)
          {
            value: $branch,
            description: (
              if $has_worktree {
                $"existing worktree at (git-feature-worktree-path $branch)"
              } else {
                "existing branch"
              }
            )
          }
        }
  } catch {
    []
  }
}

# Helper for git commit completion
def "nu-complete git-commits" [] {
  try {
    ^git log -n 20 --pretty=%h»¦«%s
      | lines
      | split column "»¦«" value description
  } catch {
    []
  }
}

# Display a formatted git log with commit hash, author, message, and relative time.
export def "log" [
	lines: int = 10  # Number of commits to display (default: 10)
] {
	^git log --pretty=%h»¦«%al»¦«%s»¦«%ah
		| lines
		| split column "»¦«" sha1 committer desc merged_at
		| first $lines
}

# Fetch with pruning and pull changes to current branch.
export def "pull" [] {
  git fetch --prune
  ^git pull
}

# Discard all staged and unstaged changes.
export def "discard" [] {
	git reset --hard
}

# Change to an existing feature worktree, or create it if missing.
export def --env "wt switch" [
  branchName: string@"nu-complete git-features" # Branch name
  main?: string                                 # Main branch name (auto-inferred if not provided)
] {
  let mainBranch = (git-main-branch $main)
  cd (git-open-feature-worktree $branchName $mainBranch)
}

# Complete feature development by removing the current feature worktree safely.
export def --env "wt finish" [
  main?: string # Main branch name (auto-inferred if not provided)
] {
  let mainBranch = (git-main-branch $main)
  let currentBranch = (git-current-branch)
  let currentPath = (git-current-worktree-path)
  let primaryPath = (git-primary-worktree-path)

  if ($currentPath == $primaryPath) {
    error make {
      msg: $"git wt finish must be run from a feature worktree, not the primary ($mainBranch) worktree."
    }
  }

  git-update-main-worktree $mainBranch

  cd $primaryPath
  ^git worktree remove $currentPath
  ^git branch -d $currentBranch

}

# Merge the updated default branch into the current feature worktree.
export def "wt merge" [
  main?: string # Main branch name (auto-inferred if not provided)
] {
  let mainBranch = (git-main-branch $main)
  let currentBranch = (git-current-branch)
  let currentPath = (git-current-worktree-path)
  let primaryPath = (git-primary-worktree-path)

  if ($currentPath == $primaryPath) {
    error make {
      msg: $"git wt merge must be run from a feature worktree, not the primary ($mainBranch) worktree."
    }
  }

  if ($currentBranch == $mainBranch) {
    error make { msg: $"Already on the default branch: ($mainBranch)" }
  }

  git-update-main-worktree $mainBranch
  ^git merge $mainBranch
}

# List all remote branches with metadata.
export def "branches remote" [] {
	git branch --remote --format='%(refname:lstrip=3)»¦«%(authoremail)»¦«%(contents:subject)»¦«%(authordate:relative)' 
		| lines 
		| split column '»¦«' name author subject date
}


# List all local branches with metadata.
export def "branches local" [] {
	git branch --format='%(refname:short)»¦«%(authoremail)»¦«%(contents:subject)»¦«%(authordate:relative)' 
		| lines 
		| split column '»¦«' name author subject date
}

# Push on stereoids; optionally stage `.` and push.
export def "push" [
  message?: string # Commit message (omitting triggers ^git push)
] {
  if ($message != null) {
    git add .
    git commit -m $message
  }
  ^git push
}

# Initialize a new git repository and add a default remote.
export def --env "init" [
  project_name?: string # Project name; it will be used for the remote git and local dir.
  ...args: string # Arguments to pass to git init
] {
  let is_flag = ($project_name != null and ($project_name | str starts-with "-"))
  
  let actual_project_name = if ($project_name == null or $is_flag) {
    $env.PWD | path basename
  } else {
    let target_dir = ([$nu.home-dir "code" $project_name] | path join)
    mkdir $target_dir 
    cd $target_dir
    $project_name
  }

  let git_args = if $is_flag {
    [$project_name] | append $args
  } else {
    $args
  }

  ^git init ...$git_args
  let remote_url = $"git@github.com:compilercomplied/($actual_project_name).git"
  try {
    ^git remote add origin $remote_url
  } catch { |err|
    logger log warn --without-timestamp $"Failed to add remote: ($err.msg)"
  }
}

# Clone a repository and cd into it.
export def --env clone [
  repo: string      # The repository url
  dir?: string      # Optional directory name
] {

	let target_dir = if ($dir != null) {
		$dir
  } else {
		(
			$repo | split row "/" | last | split row ":" | last
			| str replace --regex '\.git$' ''
		)
	}

	^git clone $repo $target_dir
	print $"cd into '($target_dir)'"
	cd $target_dir
}

# Rebase the current branch onto a commit with a backtrack offset.
export def "rebase" [
  commit: string@"nu-complete git-commits" # The base commit
  backtrack: int                           # Number of commits to go back from the selected commit
] {
  ^git rebase $"($commit)~($backtrack)"
}

# Undo the last N commits while keeping their changes staged.
export def "uncommit" [
  count: int = 1 # Number of commits to uncommit
] {
  if $count < 1 {
    error make { msg: "count must be at least 1" }
  }

  ^git reset --soft $"HEAD~($count)"
}
