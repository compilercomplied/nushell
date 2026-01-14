use host.nu *
use git_lib.nu get-git-repo-name


def _get-passphrase [] {
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
		print "Using inferred pulumi passphrase"
		open $secret_file | str trim
	} else {
		print "No pulumi passphrase was detected for this project"
		null
	}
}

export def --wrapped main [...args] {
	let passphrase = _get-passphrase

	if $passphrase != null {
		with-env { PULUMI_CONFIG_PASSPHRASE: $passphrase } {
			^pulumi -C iac ...$args
		}
	} else {
		^pulumi -C iac ...$args
	}
}

def _get-iac-path []: nothing -> string {
	let path = ($env.PWD | path join "iac")
	validate-path-exists $path
	return $path
}
def _get-iac-envs []: nothing -> list<string> { return [ "local" "prod" ] }

# Load configuration and secrets from the 'local' stack into the shell environment.
export def --env local-env [] {
	let iac_path = _get-iac-path

	let output = main config --stack local --show-secrets --json | from json

	let configs = ($output | values | where secret == false | length)
	let secrets = ($output | values | where secret == true | length)

	let env_vars = ($output
		| transpose key data
		| each {|it| { ($it.key | split row ":" | last): $it.data.value } }
		| reduce --fold {} {|it, acc| $acc | merge $it }
	)

	$env_vars | load-env
	print $"Loaded ($configs) config values and ($secrets) secrets"
}

# Wrapper over `pulumi new` with project defaults.
export def init [
	passphrase: string # Used to setup encryption local to the repo.
]: nothing -> nothing {
	# Skip 'local'; it is created with the first command.
	let environments = (_get-iac-envs | skip 1) 
	let iac_path: string = _get-iac-path

	validate-tool-exists "pulumi"

	let project_name = get-git-repo-name

	(pulumi new typescript
		--yes														# Empty description and other defaults.
		--secrets-provider passphrase		# Local passphrase encryption.
		--stack local
		--dir $iac_path
		--name $project_name
	)

	for environment in $environments {
			main stack init $environment --secrets-provider passphrase
	}
}

# Remove all configuration and resources associated with the project.
export def prune [passphrase: string] {
	let environments = _get-iac-envs
	let iac_path: string = _get-iac-path

	let project_name = get-git-repo-name

	main destroy --yes

	for environment in $environments {
		main stack rm $environment --yes
	}

	print "Removing iac directory"
	rm -rf $iac_path
}
