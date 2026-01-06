const context = (
		"CONTEXT: You are a CLI assistant running in a terminal. "
	+ "OUTPUT: Markdown. "
	+ "STYLE: Extremely brief, concise, and direct. No filler."
)

# Autocomplete
def backends [] {
    [ "gemini", "claude" ]
}

export def q [
    prompt: string
    --backend: string@backends = "gemini"
] {
    if $backend == "gemini" {
        call_gemini $prompt
    } else if $backend == "claude" {
        call_claude $prompt
    } else {
        let valid = (backends | str join ", ")
        error make { msg: $"Unknown backend: ($backend). Supported: ($valid)" }
    }
}

def call_gemini [prompt: string] {
    if ($env.GEMINI_API_KEY? | is-empty) {
        error make { msg: "GEMINI_API_KEY environment variable is not set." }
    }

    let url = ("https://generativelanguage.googleapis.com/v1beta/models"
			+ "/gemini-2.0-flash:generateContent")

    let body = {
        contents: [{
            parts: [{ text: "($context)\n\n($prompt)" }]
        }]
    }

    let headers = {
        "Content-Type": "application/json"
        "X-goog-api-key": $env.GEMINI_API_KEY
    }

    let response = http post $url ($body | to json) --headers $headers
        | get candidates.0.content.parts.0.text

    render $response
}

def call_claude [prompt: string] {
    if ($env.ANTHROPIC_API_KEY? | is-empty) {
        error make { msg: "ANTHROPIC_API_KEY environment variable is not set." }
    }

    let url = "https://api.anthropic.com/v1/messages"
    
    let body = {
        model: "claude-haiku-4-5"
        max_tokens: 1024
        messages: [{
            role: "user"
            content: $"($context)\n\n($prompt)"
        }]
    }

    let headers = {
        "x-api-key": $env.ANTHROPIC_API_KEY
        "anthropic-version": "2023-06-01"
        "content-type": "application/json"
    }

    let response = http post $url ($body | to json) --headers $headers
        | get content.0.text

    render $response
}

def render [response: string] {
    if (which glow | is-not-empty) {
        $response | glow
    } else {
        $response
    }
}
