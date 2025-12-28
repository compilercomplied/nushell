# ##############################################################################
# Optional environment files
# ##############################################################################
# --- OS-specific modules ---
source-env (if ([$nu.default-config-dir, 'lib/windows.nu'] | path join | path exists) {
    [$nu.default-config-dir, 'lib/windows.nu'] | path join
} else { null })

# --- Environment Modules ---
source-env (if ([$nu.default-config-dir, 'env/secrets.nu'] | path join | path exists) {
    [$nu.default-config-dir, 'env/secrets.nu'] | path join
} else { null })

source-env (if ([$nu.default-config-dir, 'env/work.nu'] | path join | path exists) {
    [$nu.default-config-dir, 'env/work.nu'] | path join
} else { null })
