$env.config = { show_banner: false }


# --- Modules ------------------------------------------------------------------
use lib/chat_gpt.nu *
use lib/gud.nu
use lib/nocker.nu
use lib/lw.nu
# use lib/fnm.nu


# --- Env modifications --------------------------------------------------------
fnm env --json | from json | load-env
$env.path = $env.path | append $env.FNM_MULTISHELL_PATH

$env.CODE_DIR = $"($env.HOMEPATH)/code"
source ~/.cache/starship/init.nu

# CsharpRepl with terminal colours.
export alias csre = csharprepl --useTerminalPaletteTheme --useUnicode
export alias rider = rider64

