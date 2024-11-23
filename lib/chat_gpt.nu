# Throw a prompt @chatgpt chat completions engine. Defaults to gpt-3.5-turbo.
# Optionally append a file to the prompt as additional context.
export def "chat-gpt" [
	prompt: string,	# Raw prompt to send.
	file?: string	# Append contents of this file to the end of the prompt.
] {

	let api_url = 'https://api.openai.com/v1/chat/completions'
	let auth_header_value = $'Bearer ($env.OPENAI_API_KEY)'
	let engine = "gpt-4-turbo"

	let message = (
		if ($file == null) { $prompt } 
		else { $"($prompt)\n(open -r $file)" }
	)

	# `http` command requires the body to be a valid json object (do not
	# stringify).
	let payload = { "model": $engine, "messages": [ { "role": "user", "content": $message } ] }

	# `http` failures bubble up; setting a variable with this won't obfuscate 
	# errors. For some weird reason nushell still does not support multiline 
	# command parsing, so it is not as readable as it should.
	let response = (http post --allow-errors --full $api_url $payload -H [Authorization $auth_header_value] -t application/json)

	if ($response.status == 200) {
		echo $response.body.choices.message.content | to text
	} else {
		# Helps debugging failure
		echo $response
	}

}

# Map alias.
export alias h = chat-gpt
