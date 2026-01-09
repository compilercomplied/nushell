# Autocomplete for methods
def methods [] {
    [ "get", "post", "put", "delete", "patch" ]
}

# Wrapper over nushell's builtin http to simplify making requests to
# restful APIs.
export def main [
    method: string@methods
    url: string
    body?: any # Either a string pointing to a file or a nushell record
] {
    let headers = if ($env.rest_authorization? | is-not-empty) {
        { Authorization: $env.rest_authorization }
    } else {
        {}
    }

    let request_body = if ($body | is-not-empty) {
        if ($body | describe) == "string" {
            open $body
        } else {
            $body
        }
    } else {
        {}
    }

    match ($method | str downcase) {
        "get" => {
            http get $url --headers $headers
        }
        "delete" => {
            http delete $url --headers $headers
        }
        "post" => {
            http post $url $request_body --headers $headers -t application/json
        }
        "put" => {
            http put $url $request_body --headers $headers -t application/json
        }
        "patch" => {
            http patch $url $request_body --headers $headers -t application/json
        }
        _ => {
            error make { msg: $"Unsupported method: ($method)" }
        }
    }
}
