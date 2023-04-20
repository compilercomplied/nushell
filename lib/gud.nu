
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