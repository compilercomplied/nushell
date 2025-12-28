
# Configure prompt
$env.config = { show_banner: false }
source ~/.cache/starship/init.nu

# Configure secrets
source-env configuration/environment.nu

# Load shell functions
use wrappers/naz.nu
use wrappers/nit.nu
use wrappers/nocker.nu
use wrappers/nubectl.nu

use commands/llm.nu *
use commands/db.nu
