
export def validate-tool-exists [toolname: string] {

    if (which $toolname | is-empty) {
        error make { msg: (
					$"Required '($toolname)' is not installed in this system"
					+ " or not available in $PATH"
				)}
    }
}
