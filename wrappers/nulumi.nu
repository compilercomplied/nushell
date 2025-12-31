use ../lib/host.nu validate-tool-exists
use ../lib/git.nu get-git-repo-name

# Wrapper over `pulumi new` with project defaults.
export def init [
	passphrase: string # Used to setup encryption local to the repo.
]: nothing -> nothing {

	validate-tool-exists "pulumi"

	let projectName = get-git-repo-name

	with-env { PULUMI_CONFIG_PASSPHRASE: $passphrase } {
		(pulumi new typescript
			--yes														# Empty description and other defaults.
			--dir iac												# Target directory.
			--secrets-provider passphrase		# Local passphrase encryption.
			--stack local
			--stack prod
			--name $projectName
		)
	}
}
