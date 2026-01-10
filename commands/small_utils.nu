
# Create directory and `cd` into it.
export def --env mkcd [dirname: string] {
	# Normalize to absolute path so we expand shorthands like `~`.
	let abspath = ($dirname | path expand)
	mkdir $abspath
	cd $abspath
}
