$env.config = { show_banner: false }
source ~/.cache/starship/init.nu


# --- OS-specific modules ------------------------------------------------------
if ([$nu.default-config-dir, 'lib/windows.nu'] | path join | path exists) {
    source-env ([$nu.default-config-dir, 'lib/windows.nu'] | path join)
}

# --- Modules ------------------------------------------------------------------
if ([$nu.default-config-dir, 'lib/secrets.nu'] | path join | path exists) {
    source-env ([$nu.default-config-dir, 'lib/secrets.nu'] | path join)
}

if ([$nu.default-config-dir, 'lib/work.nu'] | path join | path exists) {
    source-env ([$nu.default-config-dir, 'lib/work.nu'] | path join)
}

use lib/llm.nu *
use lib/naz.nu
use lib/gud.nu
use lib/nocker.nu
use lib/nubectl.nu
use lib/db.nu