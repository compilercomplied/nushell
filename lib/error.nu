# Utility for raising unspanned errors uniformly across the codebase.
export def mkerr [msg: string] {
    error make --unspanned {msg: $msg}
}
