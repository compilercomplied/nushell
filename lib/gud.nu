
# Purge all local branches except for main.
export def "clean-features" [] {
  git branch --list 
    | lines --skip-empty
    | str substring 2.. 
    | where $it != 'master'
	| where $it != 'main'
    | each { |it| git branch -D $it }
}

# Readable log that defaults to 10 commits.
export def "log" [lines: int = 10] {
	git log --pretty=%h»¦«%al»¦«%s»¦«%ah
		| lines
		| split column "»¦«" sha1 committer desc merged_at
		| first $lines
}

# Fetch prune and pull changes to current branch
export def "pull" [] {
  git fetch --prune
  git pull
}

# Checkout master and prune local branches.
export def "finish-feature" [
  main?: string # Main branch (defaults to master).
] {
  let mainBranch = (
		if ($main == null) { "master" } 
		else { $main }

  )
  git checkout $mainBranch
  git fetch --prune
  git pull
  clean-features

}

# Checkout master, pull changes and merge into current branch.
export def "merge-master" [
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

# List remote branches
export def "branches remote" [
] {
	git branch --remote --format='%(refname:lstrip=3)»¦«%(authoremail)»¦«%(contents:subject)»¦«%(authordate:relative)' 
		| lines 
		| split column '»¦«' name author subject date
}


# List local branches
export def "branches local" [
] {
	git branch --format='%(refname:short)»¦«%(authoremail)»¦«%(contents:subject)»¦«%(authordate:relative)' 
		| lines 
		| split column '»¦«' name author subject date
}

