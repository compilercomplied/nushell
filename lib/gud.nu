
# Purge all local branches except for main.
export def "gud clean-features" [] {
  git branch --list 
    | lines --skip-empty
    | str substring 2.. 
    | where $it != 'master'
	| where $it != 'main'
    | each { |it| git branch -D $it }
}

# Readable log that defaults to 10 commits.
export def "gud log" [lines: int = 10] {
	git log --pretty=%h»¦«%al»¦«%s»¦«%ah
		| lines
		| split column "»¦«" sha1 committer desc merged_at
		| first $lines
}

# Fetch prune and pull changes to current branch
export def "gud pull" [] {
  git fetch --prune
  git pull
}

# Checkout master and prune local branches.
export def "gud finish-feature" [
  main?: string # Main branch (defaults to master).
] {
  let mainBranch = (
		if ($main == null) { "master" } 
		else { $main }

  )
  git checkout $mainBranch
  git fetch --prune
  git pull
  gud clean-features

}

# Checkout master, pull changes and merge into current branch.
export def "gud merge-master" [
  main?: string # Main branch (defaults to master).
] {
  let mainBranch = (
		if ($main == null) { "master" } 
		else { $main }

  )

  let currentBranch = (
    git status | lines | first 1 | to text | str substring (10..) | str trim
  )

  git checkout $mainBranch
  git fetch
  git pull
  git checkout $currentBranch
  git merge $mainBranch

  ""
}
