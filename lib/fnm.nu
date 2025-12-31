
export def bootstrap-fnm-env []: nothing -> record {
		mut env_vars = {}
		let pwsh_vars = (
				^fnm env --shell power-shell | 
				lines | 
				parse "$env:{key} = \"{value}\""
		)

		# fnm-prefixed vars
		for v in ($pwsh_vars | slice 1..) { 
				$env_vars = ($env_vars | insert $v.key $v.value) 
		}

		# path
		let env_used_path = (
			$env | columns | where {str downcase | $in == "path"} | get 0
		)
		let path_value = ($pwsh_vars | get 0.value | split row (char esep))
		$env_vars = ($env_vars | insert $env_used_path $path_value)

		return $env_vars
}
