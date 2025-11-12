# Completion for AKS cluster names
def "nu-complete aks clusters" [] {
	$env.aks_clusters | columns
}

# Completion for database resource types
def "nu-complete db resources" [] {
	["pgsql" "mssql"]
}

# ==============================================================================
# Public functions
# ==============================================================================

# List key vaults
export def "keyvaults" [
	--owned = true  # Filter to only show keyvaults in owned resource groups
] {
	let vaults = (az keyvault list --output json
		| from json
		| select name resourceGroup
        | sort-by resourceGroup name)
	
	if $owned {
		$vaults | where resourceGroup in $env.resource_groups
	} else {
		$vaults
	}
}

# List secrets in a keyvault
export def "secrets" [
	keyvault: string  # Name of the keyvault
] {
	az keyvault secret list --vault-name $keyvault --output json
		| from json
        | where attributes.enabled == true
        | select name attributes.created
}

# Show the secret value from a specific keyvault
export def "secret" [
	keyvault: string  # Name of the keyvault
	name: string      # Name of the secret
] {
	az keyvault secret show --vault-name $keyvault --name $name --output json
    | from json
    | get value
}

# Login to k8s cluster.
export def "aks login" [
    cluster: string@"nu-complete aks clusters"  # Cluster name
] {
    if ($cluster not-in $env.aks_clusters) {
        error make {msg: $"unknown cluster name: ($cluster). Valid options are: ($env.aks_clusters | columns | str join ', ')"}
    }
    
    let config = $env.aks_clusters | get $cluster
    az aks get-credentials --name $config.name --resource-group $config.resource_group --subscription $config.subscription
}

# List repositories in Azure Container Registry
export def "acr repos" [
	--owned = true  # Filter to only show repositories starting with 'language-tools'
] {
	let repos = (az acr repository list --name $env.acr_name --output json | from json)
	
	if $owned {
		$repos | where ($it | str starts-with language-tools) 
	} else {
		$repos
	}
}

# List tags for an Azure Container Registry repository
export def "acr tags" [
	repository: string  # Name of the repository
	--limit: int = 10   # Maximum number of tags to retrieve
] {
	az acr repository show-tags --name $env.acr_name --repository $repository --detail --orderby time_desc --top $limit --output json
		| from json 
		| select name createdTime lastUpdateTime
}

# Login to Azure Container Registry for Docker
export def "acr login" [] {
	let token = (az acr login --name $env.acr_name --expose-token --output json 
		| from json 
		| get accessToken)
	
	docker login $"($env.acr_name).azurecr.io" --username 00000000-0000-0000-0000-000000000000 --password $token
}

# Get access token for Azure database resources
export def "access-tokens" [
	resource: string@"nu-complete db resources"  # Database resource type: { pgsql | mssql }
] {
	if ($resource == "mssql") {
		az account get-access-token --resource-type oss-rdbms --output json 
			| from json 
			| get accessToken
	} else if ($resource == "pgsql") {
		az account get-access-token --resource https://token.postgres.cosmos.azure.com --output json 
			| from json 
			| get accessToken
	} else {
		error make {msg: $"unknown database resource type: ($resource). Valid options are: pgsql, mssql"}
	}
}