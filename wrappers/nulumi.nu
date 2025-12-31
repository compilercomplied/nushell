use ../lib/host.nu validate-tool-exists
use ../lib/git.nu get-git-repo-name

# Wrapper over `pulumi new` with project defaults.
export def init [
	passphrase: string # Used to setup encryption local to the repo.
]: nothing -> nothing {

	validate-tool-exists "pulumi"

	let projectName = get-git-repo-name
	# Pulumi uses this environment variable to set the passphrase instead of 
	# setting it as part of the CLI args.
	# Nushell scopes this to the function, so it won't pollute the environment.
	$env.PULUMI_CONFIG_PASSPHRASE = $passphrase

	(pulumi new typescript
		--yes														# Use empty description and other defaults.
		--dir iac												# Target directory.
		--secrets-provider passphrase		# Local passphrase encryption.
		--stack local
		--stack prod
		--name $projectName
	)
}
