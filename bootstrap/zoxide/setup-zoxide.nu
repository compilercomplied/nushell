print "Initializing zoxide..."

let zoxide_exists = (which zoxide | is-not-empty)
let file_exists = ("~/.zoxide.nu" | path expand | path exists)

if $zoxide_exists and not $file_exists {
    zoxide init nushell | save -f ~/.zoxide.nu
} else {

	let zoxide_visual = if $zoxide_exists {
		$"(ansi green)✓(ansi reset)"
	} else { $"(ansi red)✗(ansi reset)"}

	let file_visual = if $file_exists {
		$"(ansi green)✓(ansi reset)"
	} else { $"(ansi red)✗(ansi reset)" }

		print $"Skipping: [($zoxide_visual)] Zoxide [($file_visual)] Zoxide config"

}

