# ##############################################################################
# Optional environment files
# ##############################################################################
# --- OS-specific modules ---
source-env (if ($nu.os-info.name == 'windows' and ([$nu.default-config-dir, 'host/windows.nu'] | path join | path exists)) {
	[$nu.default-config-dir, 'host/windows.nu'] | path join
} else { null })

# --- Environment Modules ---
source-env (if ([$nu.default-config-dir, 'env/secrets.nu'] | path join | path exists) {
	[$nu.default-config-dir, 'env/secrets.nu'] | path join
} else { null })
# We double check here `env/secrets.nu` because we can't log inside source-env
# due to nushell's parse-time checks.
if (not ([$nu.default-config-dir, 'env/secrets.nu'] | path join | path exists)) {
	use logger.nu log
	log warn --without-timestamp "`env/secrets.nu` not present"
}

source-env (if ([$nu.default-config-dir, 'env/work.nu'] | path join | path exists) {
	[$nu.default-config-dir, 'env/work.nu'] | path join
} else { null })

source-env (if ([$nu.default-config-dir, '~/.zoxide.nu'] | path join | path exists) {
	[$nu.default-config-dir, '~/.zoxide.nu'] | path join
} else { null })

if not (which mise | is-empty) {
	let mise_file = ([$nu.default-config-dir, 'env/mise.nu'] | path join)
	if not ($mise_file | path exists) {
		^mise activate nu | save -f $mise_file
	}
}

source-env (if ([$nu.default-config-dir, 'env/mise.nu'] | path join | path exists) {
	[$nu.default-config-dir, 'env/mise.nu'] | path join
} else { null })

source-env ([$nu.default-config-dir, 'host/system.nu'] | path join)

export-env {
	if not (which fnm | is-empty) {

		use ../lib/fnm.nu bootstrap-fnm-env
		bootstrap-fnm-env | load-env

		if ('__fnm_hooked' not-in $env) {
			$env.__fnm_hooked = true
			$env.config = ($env | default {} config).config
			$env.config = ($env.config | default {} hooks)
			$env.config = ($env.config | update hooks ($env.config.hooks | default {} env_change))
			$env.config = ($env.config | update hooks.env_change ($env.config.hooks.env_change | default [] PWD))
			$env.config = ($env.config | update hooks.env_change.PWD ($env.config.hooks.env_change.PWD | append { |before, after|
				if ('FNM_DIR' in $env) and ([.nvmrc .node-version] | path exists | any { |it| $it }) {
					(^fnm use); (fnm-env | load-env)
				}
			}))
		}
	}
}
