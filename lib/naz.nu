# Completion helper for AKS cluster names
def "nu-complete aks clusters" [] {
	$env.aks_clusters | columns
}

# Completion helper for database resource types
def "nu-complete db resources" [] {
	["pgsql" "mssql"]
}

# ==============================================================================
# Azure Key Vault Operations
# ==============================================================================

# List all Azure Key Vaults accessible to the current account.
export def "keyvaults" [
	--owned  # Filter to show only keyvaults in owned resource groups (from $env.resource_groups)
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

# List all enabled secrets in a specific Key Vault.
export def "secrets" [
	keyvault: string  # Name of the Key Vault
] {
	az keyvault secret list --vault-name $keyvault --output json
		| from json
        | where attributes.enabled == true
        | select name attributes.created
}

# Retrieve the value of a specific secret from a Key Vault.
export def "secret" [
	keyvault: string  # Name of the Key Vault
	name: string      # Name of the secret to retrieve
] {
	az keyvault secret show --vault-name $keyvault --name $name --output json
    | from json
    | get value
}

# ==============================================================================
# Azure Kubernetes Service (AKS) Operations
# ==============================================================================

# Authenticate kubectl with an AKS cluster.
export def "aks login" [
    cluster: string@"nu-complete aks clusters"  # Cluster name (use tab completion)
] {
    if ($cluster not-in $env.aks_clusters) {
        error make {msg: $"unknown cluster name: ($cluster). Valid options are: ($env.aks_clusters | columns | str join ', ')"}
    }
    
    let config = $env.aks_clusters | get $cluster
    az aks get-credentials --name $config.name --resource-group $config.resource_group --subscription $config.subscription
}

# ==============================================================================
# Azure Container Registry (ACR) Operations
# ==============================================================================

# List all repositories in the Azure Container Registry.
export def "acr repos" [
	--owned  # Filter to show only repositories starting with 'language-tools'
] {
	let repos = (az acr repository list --name $env.acr_name --output json | from json)
	
	if $owned {
		$repos | where ($it | str starts-with language-tools) 
	} else {
		$repos
	}
}

# List image tags for a specific ACR repository, sorted by most recent.
export def "acr tags" [
	repository: string  # Name of the repository
	--limit: int = 10   # Maximum number of tags to retrieve (default: 10)
] {
	az acr repository show-tags --name $env.acr_name --repository $repository --detail --orderby time_desc --top $limit --output json
		| from json 
		| select name createdTime lastUpdateTime
}

# Authenticate Docker with Azure Container Registry.
export def "acr login" [] {
	let token = (az acr login --name $env.acr_name --expose-token --output json 
		| from json 
		| get accessToken)
	
	docker login $"($env.acr_name).azurecr.io" --username 00000000-0000-0000-0000-000000000000 --password $token
}

# ==============================================================================
# Azure Database Operations
# ==============================================================================

# Get an access token for Azure database resources.
export def "access-tokens" [
	resource: string@"nu-complete db resources"  # Database resource type: pgsql or mssql
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