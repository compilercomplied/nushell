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

source-env (if ([$nu.default-config-dir, 'env/work.nu'] | path join | path exists) {
	[$nu.default-config-dir, 'env/work.nu'] | path join
} else { null })

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
