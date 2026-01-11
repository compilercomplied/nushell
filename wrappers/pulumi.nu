use host.nu validate-tool-exists
use git_lib.nu get-git-repo-name


export def --wrapped main [...args] {
	# Attempt to resolve passphrase config using a specific approach to secrets
	# management. The expectation is that a secrets repo is cloned to
	# `$HOME/secrets` and that this secrets repo has the following structure:
	# └─── projects
	# 	 ├── $project-name-1
	# 	 │   ├── .env
	# 	 │   └── pulumi-passphrase.txt
	# 	 └─── $project-name-2
	# 			 ├── .env
	# 			 └── pulumi-passphrase.tx
	# Where `$project-name` is just the git repo name on the remote.
	let project_name = try { get-git-repo-name } catch { null }
	let secret_file = if $project_name != null {
		($env.HOME | path join "secrets" "projects" $project_name "pulumi-passphrase.txt")
	} else {
		null
	}

	if ($secret_file != null) and ($secret_file | path exists) {
		let passphrase = (open $secret_file | str trim)
		with-env { PULUMI_CONFIG_PASSPHRASE: $passphrase } {
			^pulumi -C iac ...$args
		}
	} else {
		^pulumi -C iac ...$args
	}
}

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

	if not ($iac_path | path exists) {
		error make { msg: $"IaC directory '($iac_path)' does not exist" }
		return
	}

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
