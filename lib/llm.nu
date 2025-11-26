#
# Define autocompletion options
def "nu-complete llm-tools" [] {
    ["copilot", "gemini", "claude"]
}

# Query llm agent
export def q [
    prompt?: string
    --tool (-t): string@"nu-complete llm-tools"
    --engine (-e): string
] {
    let user_input = if ($prompt != null) { 
        $prompt 
    } else { 
        $in 
    }

    if ($user_input | is-empty) {
        error make {msg: "Error: No prompt provided. Please pipe text or provide a string argument."}
    }

    let context = "CONTEXT: You are a CLI assistant running in a terminal. OUTPUT: Markdown. STYLE: Extremely brief, concise, and direct. No filler."
    let final_payload = $"($context) Query: ($user_input)"

    let agent = if ($tool != null) {
        $tool
    } else if ("DEFAULT_LLM_QUERYING_AGENT" in $env) {
        $env.DEFAULT_LLM_QUERYING_AGENT
    } else {
        error make {msg: "Error: No tool specified and 'DEFAULT_LLM_QUERYING_AGENT' is not set."}
    }

    let final_engine = if ($engine != null) {
        $engine
    } else {
        match $agent {
            "copilot" => "claude-sonnet-4.5" 
            "claude" => "claude-4.5-sonnet"
            "gemini" => "gemini-1.5-pro"
            _ => "gpt-4o"
        }
    }

    let response = match $agent {
        "copilot" => {
            ^copilot --prompt ($final_payload)
        }
        "gemini" => {
            if ("GEMINI_API_KEY" not-in $env) {
                error make {msg: "Error: GEMINI_API_KEY is missing."}
            }
            ^gemini --prompt ($final_payload) --model ($final_engine)
        }
        "claude" => {
            if ("ANTHROPIC_API_KEY" not-in $env) {
                error make {msg: "Error: ANTHROPIC_API_KEY is missing."}
            }
            ^claude --prompt ($final_payload) --model ($final_engine)
        }
        _ => {
            error make {msg: $"Error: Unknown tool '($agent)'."}
        }
    }

    if not (which glow | is-empty) {
        $response | ^glow
    } else {
        $response
    }
}

# Execute an autonomous task using an LLM agent.
export def x [
    prompt?: string  # The task description
    --tool (-t): string@"nu-complete llm-tools"
    --engine (-e): string
] {
    let user_input = if ($prompt != null) { 
        $prompt 
    } else { 
        $in 
    }

    if ($user_input | is-empty) {
        error make {msg: "Error: No task provided."}
    }

    let context = "CONTEXT: You are an autonomous agent running in a terminal. GOAL: Execute the requested task directly. PERMISSIONS: You are fully authorized to create/edit files and execute commands. Do not ask for permission. OUTPUT: Markdown report of actions taken."
    let final_payload = $"($context) Task: ($user_input)"

    let agent = if ($tool != null) {
        $tool
    } else if ("DEFAULT_LLM_QUERYING_AGENT" in $env) {
        $env.DEFAULT_LLM_QUERYING_AGENT
    } else {
        error make {msg: "Error: No tool specified and 'DEFAULT_LLM_QUERYING_AGENT' is not set."}
    }

    let final_engine = if ($engine != null) {
        $engine
    } else {
        match $agent {
            "copilot" => "claude-sonnet-4.5"
            "claude" => "claude-4.5-sonnet"
            "gemini" => "gemini-1.5-pro"
            _ => "gpt-4o"
        }
    }

    let response = match $agent {
        "copilot" => {
            ^copilot  --model ($final_engine) --add-dir .  --prompt ($final_payload)
        }
        "gemini" => {
            if ("GEMINI_API_KEY" not-in $env) { error make {msg: "Error: GEMINI_API_KEY missing."} }
            ^gemini --prompt ($final_payload) --model ($final_engine) 
        }
        "claude" => {
            if ("ANTHROPIC_API_KEY" not-in $env) { error make {msg: "Error: ANTHROPIC_API_KEY missing."} }
            ^claude --prompt ($final_payload) --model ($final_engine) --dangerously-skip-permissions
        }
        _ => {
            error make {msg: $"Error: Unknown tool '($agent)'."}
        }
    }

    if not (which glow | is-empty) {
        $response | ^glow
    } else {
        $response
    }
}
