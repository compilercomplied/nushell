export def q [prompt: string] {

    let url = "https://generativelanguage.googleapis.com/v1beta/models"
			+ "/gemini-2.0-flash:generateContent"
    
    let context = "CONTEXT: You are a CLI assistant running in a terminal. "
		+ "OUTPUT: Markdown. "
		+ "STYLE: Extremely brief, concise, and direct. No filler."

    let body = {
        contents: [{
            parts: [{ text: $"($context)\n\n($prompt)" }]
        }]
    }

    let headers = {
        "Content-Type": "application/json"
        "X-goog-api-key": $env.GEMINI_API_KEY
    }

    let response = http post $url ($body | to json) --headers $headers
        | get candidates.0.content.parts.0.text

    if (which glow | is-not-empty) {
        $response | glow
    } else {
        $response
    }
}
