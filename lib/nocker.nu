# List all Docker containers (running and stopped) with formatted output.
export def "containers" [] {
	docker container ls -a --format "table {{.ID}}»¦«{{.Names}}»¦«{{.State}}»¦«{{.RunningFor}}»¦«{{.Ports}}" 
		| lines 
		| skip 1 
		| parse "{ID}»¦«{Name}»¦«{State}»¦«{RunningFor}»¦«{Ports}"
}

# List all Docker images with formatted output.
export def "images" [] {
	docker image ls -a --format "table {{.ID}}»¦«{{.Repository}}»¦«{{.Tag}}»¦«{{.Size}}"
		| lines 
		| skip 1 
		| parse "{Image}»¦«{Repo}»¦«{Tag}»¦«{Size}"
}

