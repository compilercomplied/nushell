
# Placeholder work config.
let worknuPath = $"($nu.default-config-dir)/lib/lw.nu"
let worknuPresent =  ($worknuPath| path exists)
if (not $worknuPresent) {
	print $"lw.nu missing, creating empty one at '($worknuPath)'"
	touch $worknuPath
}


print $"Scaffolding starship config"
mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu
mkdir ~/.config
cp starship.toml ~/.config/starship.toml
