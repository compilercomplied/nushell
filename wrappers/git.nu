use ../lib/logger.nu

# Purge all local branches except for main and master.
export def "clean-features" [] {
  git branch --list 
    | lines --skip-empty
    | str substring 2.. 
    | where $it != 'master'
		| where $it != 'main'
    | each { |it| git branch -D $it }
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

# Create new feature branch.
export def "branch-feature" [
	branchName: string # Branch name
] {
	git checkout -b $branchName
}

# Complete feature development by switching to main branch and cleaning up.
export def "finish-feature" [
  main?: string # Main branch name (auto-inferred if not provided)
] {
  let mainBranch = (
		if ($main == null) {
			let branches = (git branch --list | lines | str substring 2.. | str trim)
			if ("main" in $branches) {
				"main"
			} else if ("master" in $branches) {
				"master"
			} else if ("trunk" in $branches) {
				"trunk"
			} else {
				"master"
			}
		} else {
			$main
		}
  )
  git checkout $mainBranch
  git pull
  clean-features

}

# Merge main branch into current feature branch.
export def "merge-master" [
  main?: string # Main branch name (defaults to 'master')
] {
  let mainBranch = (
		if ($main == null) { "master" } 
		else { $main }

  )

  let currentBranch = (
    git status | lines | first 1 | to text | str substring (10..) | str trim
  )

  git checkout $mainBranch
  git pull
  git checkout $currentBranch
  git merge $mainBranch

  ""
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
export def "init" [
  ...args: string # Arguments to pass to git init
] {
  ^git init ...$args
  let repo_name = ($env.PWD | path basename)
  let remote_url = $"git@github.com:compilercomplied/($repo_name).git"
  try {
    ^git remote add origin $remote_url
  } catch { |err|
    logger log warn --without-timestamp $"Failed to add remote: ($err.msg)"
  }
}
