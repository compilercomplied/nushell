# Custom completion for log levels
def "nu-complete log-levels" [] {
    [ warn, info, error, debug ]
}

export def log [
    level: string@"nu-complete log-levels"
    message: string
    --without-timestamp  # Do not print timestamp
] {
    let icon = match $level {
        "warn" => "⚠️  "
        "info" => "ℹ️  "
        "error" => "❌ "
        "debug" => "🐛 "
        _ => "unknown"
    }

		if ($icon == "unknown") {
			error make { msg: $"Unknown log level '$(level)'" }
		}

    let timestamp_section = if $without_timestamp {
        ""
    } else {
        let timestamp = (date now | format date "%H:%M:%S")
        $"(ansi purple)[($timestamp)](ansi reset) "
    }
    
    print $"($icon) ($timestamp_section)(ansi green)($message)(ansi reset)"
}
