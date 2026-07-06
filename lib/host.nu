use error.nu mkerr


export def validate-tool-exists [toolname: string] {
    if (which $toolname | is-empty) {
        mkerr (
				$"Required '($toolname)' is not installed in this system"
				+ " or not available in $PATH"
			)
    }
}


export def validate-path-exists [path: string] {
    if not ($path | path exists) {
        mkerr $"Required path '($path)' does not exist."
    }
}
