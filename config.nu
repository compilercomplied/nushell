$env.config = { show_banner: false }
source ~/.cache/starship/init.nu


# --- OS-specific modules ------------------------------------------------------
use lib/windows.nu *

# --- Modules ------------------------------------------------------------------
use lib/work.nu

use lib/llm.nu *
use lib/naz.nu
use lib/gud.nu
use lib/nocker.nu
use lib/nubectl.nu
use lib/db.nu