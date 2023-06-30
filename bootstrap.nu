
# Placeholder work config.
let worknuPath = $"($nu.default-config-dir)/lib/work.nu"
let worknuPresent =  ($worknuPath| path exists)
if (not $worknuPresent) {
	print $"Work.nu missing, creating empty one at '($worknuPath)'"
	touch $worknuPath
}


print $"Overriding starship.toml"
cp starship.toml ~/.config/starship.toml
