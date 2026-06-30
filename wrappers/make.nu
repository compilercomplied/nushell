def "nu-complete make-targets" [] {
  let makefiles = ["GNUmakefile" "Makefile" "makefile"]

  let makefile = (
    $makefiles
    | where { |candidate| $candidate | path exists }
    | get 0?
  )

  if $makefile == null {
    return []
  }

  try {
    let lines = (open --raw $makefile | lines)

    let help_entries = (
      $lines
      | each { |line| $line | str trim }
      | where { |line| $line | str contains '@echo "  ' }
      | parse '@echo "  {value} - {description}"'
      | each { |entry|
          {
            value: ($entry.value | str trim)
            description: ($entry.description | str trim)
          }
        }
    )

    if not ($help_entries | is-empty) {
      return $help_entries
    }

    $lines
      | where { |line|
          ($line | str trim) != ""
          and not ($line | str starts-with "#")
          and not ($line | str starts-with ".")
          and not ($line | str starts-with "\t")
          and ($line | str contains ":")
          and not ($line | str contains "=")
        }
      | parse "{value}:"
      | each { |entry| { value: ($entry.value | str trim), description: "" } }
  } catch {
    []
  }
}

export def --wrapped main [
  target?: string@"nu-complete make-targets"
  ...args: string
] {
  if $target == null {
    ^make ...$args
  } else {
    ^make $target ...$args
  }
}
