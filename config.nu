$env.config = { show_banner: false }
source ~/.cache/starship/init.nu


# --- Modules ------------------------------------------------------------------
use lib/llm.nu *
use lib/gud.nu
use lib/nocker.nu
if ("lib/work.nu" | path exists) {
    use lib/work.nu
}
use lib/naz.nu

# --- OS-specific modules ------------------------------------------------------
if $nu.os-info.name == "windows" {
    use lib/windows.nu
}