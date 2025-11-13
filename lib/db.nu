# Database query module for MSSQL and Postgres with Entra ID support
# Configuration is loaded from $env.db_configs (see work.nu)

# Validate that required external tools are available
def check-tool [tool: string] {
    if (which $tool | is-empty) {
        error make {msg: $"Required tool '($tool)' not found in PATH. Please install it first."}
    }
}

# Internal helper to get Azure Access Token for OSS RDBMS (Postgres)
def get-pg-entra-token [] {
    # Requires 'az login' to have been run previously
    check-tool "az"
    
    let result = (run-external "az" "account" "get-access-token" "--resource-type" "oss-rdbms" "--output" "json" | complete)
    
    if $result.exit_code != 0 {
        error make {msg: $"Failed to get Azure token. Make sure you're logged in with 'az login'. Error: ($result.stderr)"}
    }
    
    let token_json = ($result.stdout | from json)
    return $token_json.accessToken
}

# Internal helper to get Azure Access Token for SQL Database
def get-mssql-entra-token [] {
    # For MSSQL, we use the SQL Database resource
    check-tool "az"
    
    let result = (run-external "az" "account" "get-access-token" "--resource" "https://database.windows.net/" "--output" "json" | complete)
    
    if $result.exit_code != 0 {
        error make {msg: $"Failed to get Azure token for MSSQL. Make sure you're logged in with 'az login'. Error: ($result.stderr)"}
    }
    
    let token_json = ($result.stdout | from json)
    return $token_json.accessToken
}

# Internal helper to construct MSSQL connection args
def build-mssql-args [config: record, query: string] {
    # Wrap query with FOR JSON PATH to handle special chars/newlines safely
    # SET NOCOUNT ON prevents "rows affected" messages from breaking JSON parsing
    # We wrap the user's query in a subquery and append FOR JSON PATH to get structured output
    # Strip trailing semicolon from query if present
    let clean_query = ($query | str trim | str replace --regex ';+$' '')
    let json_query = $"SET NOCOUNT ON; SELECT * FROM \(($clean_query)\) AS sub FOR JSON PATH, ROOT\('root'\), INCLUDE_NULL_VALUES;"
    
    # Build server connection string with port if specified
    let server_str = if ($config.port? != null) {
        $"($config.host),($config.port)"
    } else {
        $config.host
    }
    
    let common_flags = [
        "-S" $server_str
        "-d" $config.db
        "-y" "0"      # Max variable length (prevent JSON truncation)
        "-W"          # Remove trailing spaces
        "-h" "-1"     # No headers
        "-Q" $json_query
    ]

    if $config.auth_type == "entra" {
        # -G uses Azure Active Directory authentication
        # For non-interactive auth, we could use access token via -P flag
        return ($common_flags | append ["-G"])
    } else {
        # Basic Auth
        return ($common_flags | append ["-U" $config.user "-P" $config.pass])
    }
}

# Internal helper to construct PGSQL connection string and environment
def build-pgsql-connection [config: record] {
    # Get password (either from config or Entra token)
    let password = if $config.auth_type == "entra" {
        naz access-tokens pgsql
    } else {
        $config.pass
    }
    
    # Build connection string with optional schema
    let conn_str = if ($config.schema? != null) {
        $"host=($config.host) port=($config.port) dbname=($config.db) user=($config.user) options='-c search_path=($config.schema)'"
    } else {
        $"host=($config.host) port=($config.port) dbname=($config.db) user=($config.user)"
    }
    
    return {
        conn_str: $conn_str
        env: { PGPASSWORD: $password }
    }
}

# Custom completer for database targets
export def db-targets [] {
    if ($env.db_configs? != null) {
        $env.db_configs | transpose name config | each { |it|
            {
                value: $it.name
                description: $"($it.config.engine) - ($it.config.host)/($it.config.db)"
            }
        }
    } else {
        []
    }
}

export def query [
    target: string@db-targets,  # The key from $env.db_configs (e.g., 'local_mssql')
    query: string                # The SQL query to execute
] {
    # Load config from environment (set in work.nu)
    if ($env.db_configs? == null) {
        error make {msg: "Database configurations not found. Make sure work.nu is loaded and $env.db_configs is set."}
    }
    
    let config = ($env.db_configs | get --optional $target)

    if ($config | is-empty) {
        error make {msg: $"Configuration '($target)' not found in $env.db_configs. Available targets: ($env.db_configs | columns | str join ', ')"}
    }

    match $config.engine {
        "mssql" => {
            check-tool "sqlcmd"
            
            let args = (build-mssql-args $config $query)
            
            # Run sqlcmd. We expect a raw JSON string output.
            let raw_result = (run-external "sqlcmd" ...$args | complete)

            if $raw_result.exit_code != 0 {
                error make {
                    msg: $"MSSQL query failed on '($target)'"
                    label: {
                        text: $"($raw_result.stderr)"
                        span: (metadata $query).span
                    }
                }
            }

            # Parse: sqlcmd might output multiple lines for big JSON, we join them
            # Then we parse JSON. The wrapper put it in {root: [...]}, so we get .root
            let json_str = ($raw_result.stdout | lines | str join "")
            
            if ($json_str | is-empty) {
                return []
            }
            
            try {
                let parsed = ($json_str | from json)
                # Check if root exists and is not null
                if ($parsed.root? != null) {
                    return $parsed.root
                } else {
                    return []
                }
            } catch {
                # If JSON parsing fails, return empty table
                print $"Warning: Could not parse MSSQL result as JSON. Raw output: ($json_str)"
                return []
            }
        }
        
        "pgsql" => {
            check-tool "psql"
            
            let connection = (build-pgsql-connection $config)

            # Run psql with --csv flag for robust parsing
            let raw_result = (
                with-env $connection.env {
                    run-external "psql" $connection.conn_str "-c" $query "--csv" | complete
                }
            )

            if $raw_result.exit_code != 0 {
                error make {
                    msg: $"PGSQL query failed on '($target)'"
                    label: {
                        text: $"($raw_result.stderr)"
                        span: (metadata $query).span
                    }
                }
            }

            # Parse the CSV output into a Nushell table
            if ($raw_result.stdout | is-empty) {
                return []
            }
            
            try {
                return ($raw_result.stdout | from csv)
            } catch {
                print $"Warning: Could not parse PGSQL result as CSV. Raw output: ($raw_result.stdout)"
                return []
            }
        }
        
        _ => {
            error make {msg: $"Unsupported database engine: ($config.engine). Only 'mssql' and 'pgsql' are supported."}
        }
    }
}