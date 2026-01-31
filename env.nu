
source (if ([$nu.default-config-dir, '.ansible_nushell_env.nu'] | path join | path exists) {
	# The ansible file contains dynamic configuration for different tools that
	# need manual configuration to be added to $PATH. This is an example bit that
	# is present in .ansible_nushell_env.nu:
	# ---------------------------------------------------------------------------
	# # BEGIN ANSIBLE MANAGED BLOCK (RUST)
	# $env.PATH = ($env.PATH | prepend ($env.HOME + '/.cargo/bin'))
	# END ANSIBLE MANAGED BLOCK (RUST)
	# ---------------------------------------------------------------------------
	[$nu.default-config-dir, '.ansible_nushell_env.nu'] | path join
} else { null })
