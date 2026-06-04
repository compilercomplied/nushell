# Completion helper for AKS cluster names
def "nu-complete aks clusters" [] {
	$env.aks_clusters | columns
}

# Completion helper for database resource types
def "nu-complete db resources" [] {
	["pgsql" "mssql"]
}

# Get the list of resource groups considered "owned" by this profile.
def "owned resource groups" [] {
    let configured_resource_groups = ($env.resource_groups? | default [])
    let cluster_resource_groups = (
        $env.aks_clusters?
        | default {}
        | transpose alias config
        | each { |it| $it.config.resource_group? }
        | where { |rg| not (($rg | default "") | is-empty) }
    )

    $configured_resource_groups
    | append $cluster_resource_groups
    | uniq
}

# Resolve which subscription hosts the configured ACR.
def "resolve acr subscription" [] {
    if (($env.acr_subscription? | default "") | is-not-empty) {
        return $env.acr_subscription
    }

    let current_subscription = (az account show --query id --output tsv)
    let found_in_current = (do -i { az acr show --name $env.acr_name --subscription $current_subscription --query id --output tsv })

    if not (($found_in_current | default "") | is-empty) {
        return $current_subscription
    }

    let enabled_subscriptions = (
        az account list --query "[?state=='Enabled'].id" --output tsv
        | lines
        | where { |it| not ($it | is-empty) }
    )

    let matching_subscriptions = (
        $enabled_subscriptions
        | where { |subscription|
            let acr_id = (do -i { az acr show --name $env.acr_name --subscription $subscription --query id --output tsv })
            not (($acr_id | default "") | is-empty)
        }
    )

    if ($matching_subscriptions | is-empty) {
        error make {msg: $"could not find ACR '($env.acr_name)' in any enabled subscription. Configure $env.acr_subscription explicitly in env/work.nu."}
    }

    if (($matching_subscriptions | length) > 1) {
        error make {msg: $"ACR '($env.acr_name)' exists in multiple subscriptions: ($matching_subscriptions | str join ', '). Configure $env.acr_subscription explicitly in env/work.nu."}
    }

    $matching_subscriptions | first
}

# Resolve subscriptions that are relevant for daily work.
def "owned subscriptions" [] {
    let configured_subscriptions = (
        $env.aks_clusters?
        | default {}
        | transpose alias config
        | each { |it| $it.config.subscription? }
        | where { |subscription| not (($subscription | default "") | is-empty) }
    )

    let current_subscription = (az account show --query id --output tsv)
    [$current_subscription]
    | append $configured_subscriptions
    | uniq
}

# ==============================================================================
# Azure Key Vault Operations
# ==============================================================================

# List all Azure Key Vaults accessible to the current account.
export def "keyvaults" [
	--owned = true  # Filter to show only keyvaults in owned resource groups (from $env.resource_groups)
] {
    let subscriptions = (owned subscriptions)
	let vaults = (
        $subscriptions
        | each { |subscription|
            let in_subscription = (do -i { az keyvault list --subscription $subscription --output json | from json })
            if ($in_subscription | is-empty) {
                []
            } else {
                $in_subscription | each { |vault|
                    {
                        name: $vault.name
                        resourceGroup: $vault.resourceGroup
                        subscription: $subscription
                    }
                }
            }
        }
        | flatten
        | sort-by subscription resourceGroup name
    )
	
	if $owned {
        let owned_groups = (owned resource groups)
        if ($owned_groups | is-empty) {
            $vaults
        } else {
		    $vaults | where resourceGroup in $owned_groups
        }
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
    let subscription = (resolve acr subscription)
	let repos = (az acr repository list --name $env.acr_name --subscription $subscription --output json | from json)
	
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
    let subscription = (resolve acr subscription)
	az acr repository show-tags --name $env.acr_name --subscription $subscription --repository $repository --detail --orderby time_desc --top $limit --output json
		| from json 
		| select name createdTime lastUpdateTime
}

# Authenticate Docker with Azure Container Registry.
export def "acr login" [] {
    let subscription = (resolve acr subscription)
	let token = (az acr login --name $env.acr_name --subscription $subscription --expose-token --output json 
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