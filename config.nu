$env.config = { show_banner: false }
source ~/.cache/starship/init.nu


# --- OS-specific modules ------------------------------------------------------
if ([$nu.default-config-dir, 'lib/windows.nu'] | path join | path exists) {
    source-env ([$nu.default-config-dir, 'lib/windows.nu'] | path join)
}

# --- Modules ------------------------------------------------------------------
if ([$nu.default-config-dir, 'env/secrets.nu'] | path join | path exists) {
    source-env ([$nu.default-config-dir, 'env/secrets.nu'] | path join)
}

if ([$nu.default-config-dir, 'env/work.nu'] | path join | path exists) {
    source-env ([$nu.default-config-dir, 'env/work.nu'] | path join)
}

use wrappers/naz.nu
use wrappers/nit.nu
use wrappers/nocker.nu
use wrappers/nubectl.nu

use commands/llm.nu *
use commands/db.nu
