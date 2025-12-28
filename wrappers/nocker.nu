# List all Docker containers (running and stopped) with formatted output.
export def "containers" [] {
	docker container ls -a --format "table {{.ID}}»¦«{{.Names}}»¦«{{.State}}»¦«{{.RunningFor}}»¦«{{.Ports}}" 
		| lines 
		| skip 1 
		| parse "{ID}»¦«{Name}»¦«{State}»¦«{RunningFor}»¦«{Ports}"
}

# Remove docker containers. If no IDs are provided, removes all containers.
export def "containers rm" [
	...ids: string # The IDs of the containers to remove
] {
	let targets = if ($ids | is-empty) {
		docker container ls -aq | lines
	} else {
		$ids
	}

	if ($targets | is-empty) {
		print "No containers to remove."
	} else {
		docker container rm ...$targets
	}
}

# List all Docker images with formatted output.
export def "images" [] {
	docker image ls -a --format "table {{.ID}}»¦«{{.Repository}}»¦«{{.Tag}}»¦«{{.Size}}"
		| lines 
		| skip 1 
		| parse "{ID}»¦«{Repo}»¦«{Tag}»¦«{Size}"
}

# Remove docker images. If no IDs are provided, removes all images.
export def "images rm" [
	...ids: string # The IDs of the images to remove
] {
	let targets = if ($ids | is-empty) {
		docker image ls -aq | lines
	} else {
		$ids
	}

	if ($targets | is-empty) {
		print "No containers to remove."
	} else {
		docker image rm ...$targets
	}
}
