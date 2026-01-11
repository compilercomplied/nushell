def "nu-complete mise-tasks" [] {
	if ("mise.toml" | path exists) {
		try {
			let config = (open mise.toml)
			if ("tasks" in $config) {
				return ($config.tasks | columns)
			}
		} catch {
			return []
		}
	}
	return []
}

export def --wrapped main [...args] {
	^mise ...$args
}

export def --wrapped run [
	task: string@"nu-complete mise-tasks"
	...args
] {
	^mise run $task ...$args
}
