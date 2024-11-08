$env.config = {
	show_banner: false
}

# --- Modules ------------------------------------------------------------------
use lib/chat_gpt.nu *
use lib/gud.nu
use lib/nocker.nu
use lib/lw.nu


$env.CODE_DIR = $"($env.HOMEPATH)/code"
source ~/.cache/starship/init.nu

# CsharpRepl with terminal colours.
export alias csre = csharprepl --useTerminalPaletteTheme --useUnicode
export alias rider = rider64
