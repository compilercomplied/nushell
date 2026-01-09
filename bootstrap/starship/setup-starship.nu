print "Set up starship.toml"
mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu

mkdir ~/.config
let src = ($env.FILE_PWD | path join "starship.toml")
let dest = ("~/.config/starship.toml" | path expand)

cp -f $src $dest
