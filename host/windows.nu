# Docker wrapper for Windows that executes Docker commands through WSL
# Usage: docker <command> [args...]
# Example: docker ps -a
# Example: docker run -it ubuntu bash
export def --wrapped docker [...rest] {
    ^wsl -e docker ...$rest
}
