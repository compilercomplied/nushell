print "Set up .gitconfig"
let src = ($env.FILE_PWD | path join ".gitconfig")
let dest = ("~/.gitconfig" | path expand)
cp -f $src $dest
