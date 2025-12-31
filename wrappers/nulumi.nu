use ../lib/host.nu validate-tool-exists
use ../lib/git.nu get-git-repo-name

def _get-iac-path []: nothing -> string { return ($env.PWD | path join "iac") }
def _get-iac-envs []: nothing -> list<string> { return [ "local" "prod" ] }

# Wrapper over `pulumi new` with project defaults.
export def init [
	passphrase: string # Used to setup encryption local to the repo.
]: nothing -> nothing {
	# Skip 'local'; it is created with the first command.
	let environments = (_get-iac-envs | skip 1) 
	let iac_path: string = _get-iac-path

	validate-tool-exists "pulumi"

	let project_name = get-git-repo-name

	with-env { PULUMI_CONFIG_PASSPHRASE: $passphrase } {
		(pulumi new typescript
			--yes														# Empty description and other defaults.
			--secrets-provider passphrase		# Local passphrase encryption.
			--stack local
			--dir $iac_path
			--name $project_name
		)

		for environment in $environments {
			pulumi -C $iac_path stack init $environment --secrets-provider passphrase
		}
	}
}

# Remove all configuration and resources associated with the project.
export def prune [passphrase: string] {
	let environments = _get-iac-envs
	let iac_path: string = _get-iac-path
	let project_name = get-git-repo-name

	with-env { PULUMI_CONFIG_PASSPHRASE: $passphrase } {
		pulumi -C $iac_path destroy --yes

		for environment in $environments {
			pulumi -C $iac_path stack rm $environment --yes
		}

		print "Removing iac directory"
		rm -rf $iac_path
	}
}
