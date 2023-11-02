# Show running containers
export def "containers" [] {
	docker container ls -a --format "table {{.ID}}\\{{.Names}}\\{{.State}}\\{{.RunningFor}}\\{{.Ports}}" 
		| lines 
		| skip 1 
		| parse "{ID}\\{Name}\\{State}\\{RunningFor}\\{Ports}"
}

# Show images
export def "images" [] {
	docker image ls --format "table {{.ID}}\\{{.Repository}}\\{{.Tag}}\\{{.Size}}"
		| lines 
		| skip 1 
		| parse "{Image}\\{Repo}\\{Tag}\\{Size}"
}

