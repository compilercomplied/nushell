# Spawn a new background process using pueue.
export def spawn [
    command: block   # The command to spawn.
] {
    let config_path = $nu.config-path
    let env_path = $nu.env-path
    let source_code = (view source $command | str trim -l -c '{' | str trim -r -c '}')
    let job_id = (pueue add -p $"nu --config \"($config_path)\" --env-config \"($env_path)\" -c '($source_code)'")
    {"job_id": $job_id}
}


# Get Pueue logs.
export def log [
    id: int   # id to fetch log
] {
    pueue log $id -f --json
    | from json
    | transpose -i info
    | flatten --all
    | flatten --all
    | flatten status
}

# Get job running status.
export def status [] {
    pueue status --json
    | from json
    | get tasks
    | transpose -i status
    | flatten
    | flatten status
}

# Kill specific job.
export def kill (id: int) {
    pueue kill $id
}

# Clean job log.
export def clean () {
    pueue clean
}