# Define library directories for module resolution. This allows to import the
# modules directly instead of using relative imports.
const NU_LIB_DIRS = [
	($nu.default-config-dir | path join 'lib')
]


$env.NU_LIB_DIRS = ($env.NU_LIB_DIRS?
		| default []
		| append ($nu.default-config-dir | path join 'lib')
)

# Configure prompt
$env.config = { show_banner: false }
source ~/.cache/starship/init.nu

# Configure environment
source-env (
	[$nu.default-config-dir, 'configuration/environment.nu'] | path join
)

use wrappers/mod.nu *
use commands/llm.nu *
use commands/db.nu
use commands/rest.nu *
use commands/small_utils.nu *
