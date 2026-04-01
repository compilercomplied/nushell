# macOS-specific environment configuration

# Append /usr/local/bin to PATH if it's not already present
$env.PATH = ($env.PATH | append '/usr/local/bin' | uniq)
