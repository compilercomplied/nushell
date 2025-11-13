print $"Scaffolding starship config"
mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu
mkdir ~/.config
cp starship.toml ~/.config/starship.toml
