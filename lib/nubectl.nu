# Autocomplete for Kubernetes object types
def "nu-complete k8s-object-types" [] {
    ["pod" "deployment"]
}

# Autocomplete for system hosts (ending in .systems) from /etc/hosts
def "nu-complete system-hosts" [] {
    if $nu.os-info.name != "linux" {
        return []
    }
    open /etc/hosts 
    | lines 
    | parse -r '.*\s+(?P<host>[\w\-\.]+\.systems)(\s|$)' 
    | get host
}

# Autocomplete for Kubernetes namespaces
def "nu-complete k8s-namespaces" [] {
    let cache_dir = ($nu.temp-path | path join "nubectl-cache")
    mkdir $cache_dir
    
    let current_context = (^kubectl config current-context | str trim)
    let cache_file = ($cache_dir | path join $"namespaces-($current_context).txt")
    
    let namespaces = if ($cache_file | path exists) {
        open $cache_file | lines
    } else {
        let ns = (^kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' | split row ' ')
        $ns | save -f $cache_file
        $ns
    }
    
    ["all"] | append $namespaces
}

# Pretty print events ordered by pod then by timestamp.
export def events [ 
    namespace: string@"nu-complete k8s-namespaces" = "all" # target namespace, defaults to all namespaces
] {
    let target_namespace = if $namespace == "all" { ["-A"] } else { ["-n" $namespace] }
    
    ^kubectl get events ...$target_namespace --field-selector involvedObject.kind=Pod --sort-by=.involvedObject.name -o go-template='{{range .items}}{{.lastTimestamp}}{"»¦«"}}{{.type}}{"»¦«"}}{{.reason}}{"»¦«"}}{{.involvedObject.name}}{"»¦«"}}{{.message}}{"\n"}}{{end}}'
    | lines
    | skip 1
    | parse "{Time}»¦«{Type}»¦«{Reason}»¦«{Pod}»¦«{Message}"
}

# List pods.
export def pods [
    namespace: string@"nu-complete k8s-namespaces" = "all" # target namespace, defaults to all namespaces
] {
    let filter_namespace = $namespace != "all"
    let target_namespace = if $namespace == "all" { ["-A"] } else { ["-n" $namespace] }
    
    let result_table = ^kubectl get pods ...$target_namespace -o go-template='{{range .items}}{{.metadata.namespace}}{"»¦«"}}{{.metadata.name}}{"»¦«"}}{{.status.phase}}{"»¦«"}}{{.spec.nodeName}}{"»¦«"}}{{.status.podIP}}{"»¦«"}}{{.metadata.creationTimestamp}}{"\n"}}{{end}}'
    | lines
    | skip 1
    | parse "{Namespace}»¦«{Name}»¦«{Status}»¦«{Node}»¦«{IP}»¦«{CreationTimestamp}"
    | reject IP
    | sort-by Namespace Name

    if $filter_namespace {
        $result_table | reject Namespace
    } else {
        $result_table
    }
}

# List deployments.
export def deployments [
    namespace: string@"nu-complete k8s-namespaces" = "all" # target namespace, defaults to all namespaces
] {
    let filter_namespace = $namespace != "all"
    let target_namespace = if $namespace == "all" { ["-A"] } else { ["-n" $namespace] }
    
    let result_table = ^kubectl get deployments ...$target_namespace -o go-template='{{range .items}}{{.metadata.namespace}}{"»¦«"}}{{.metadata.name}}{"»¦«"}}{{.spec.replicas}}{"»¦«"}}{{.status.replicas}}{"»¦«"}}{{.status.updatedReplicas}}{"»¦«"}}{{.status.availableReplicas}}{"\n"}}{{end}}'
    | lines
    | skip 1
    | parse "{Namespace}»¦«{Name}»¦«{Desired}»¦«{Current}»¦«{Updated}»¦«{Available}"
    | sort-by Namespace Name

    if $filter_namespace {
        $result_table | reject Namespace
    } else {
        $result_table
    }
}

# Describe a Kubernetes object.
export def describe [
    namespace: string@"nu-complete k8s-namespaces", # target namespace, defaults to all namespaces
    object_type: string@"nu-complete k8s-object-types" # type of object (pod or deployment)
    object_name: string # name of the object
    raw: bool = false # whether to output raw nu object or rely on explore
] {
    let target_namespace = ["-n" $namespace]
    
    let command_result = ^kubectl ...$target_namespace get $object_type $object_name -o json 
    | from json 

    if ($raw) {
        $command_result
    } else {
        $command_result | explore
    }
}

# Fetch and merge kubeconfig from a remote host
export def "fetch-context" [
    host: string@"nu-complete system-hosts" # The remote host to fetch config from
] {
    print $"Connecting to ($host)..."
    
    # Check for config file location
    let config_type = (^ssh $"root@($host)" "if [ -f /etc/rancher/k3s/k3s.yaml ]; then echo k3s; elif [ -f /etc/kubernetes/admin.conf ]; then echo k8s; fi")
    
    let remote_path = if ($config_type | str trim) == "k3s" {
        "/etc/rancher/k3s/k3s.yaml"
    } else if ($config_type | str trim) == "k8s" {
        "/etc/kubernetes/admin.conf"
    } else {
        error make {msg: $"No k3s or k8s config found on ($host)."}
    }
    
    print $"Found ($config_type | str trim) config at ($remote_path). Pulling..."
    
    let temp_config = (mktemp -t $"nubectl-($host)-XXXXXX.yaml" | str trim)
    ^scp $"root@($host):($remote_path)" $temp_config
    
    print "Config pulled. modifying..."
    
    # Read as raw text and perform string replacements
    # We replace ": default" to safely target values like 'name: default', 'cluster: default', 'user: default' 
    # without risking replacing 'default' substrings in other keys or certificate data.
    let config_text = (open --raw $temp_config 
        | str replace --all "127.0.0.1" $host 
        | str replace --all "localhost" $host 
        | str replace --all ": default" $": ($host)"
    )
    
    $config_text | save -f $temp_config
    
    print "Merging into local configuration..."
    
    let kube_config_path = ($env.KUBECONFIG? | default ($env.HOME | path join ".kube" "config"))
    let kube_dir = ($env.HOME | path join ".kube")
    
    # Ensure ~/.kube directory exists
    if not ($kube_dir | path exists) {
        mkdir $kube_dir
    }

    let backup_path = $"($kube_config_path).bak"
    
    # 1. Back up current config
    if ($kube_config_path | path exists) {
        ^cp $kube_config_path $backup_path
    }
    
    # 2. Merge configs using kubectl and KUBECONFIG env var
    # We write to a temporary new file first
    let new_config_path = ($env.HOME | path join ".kube" "config_new")
    
    with-env { KUBECONFIG: $"($kube_config_path):($temp_config)" } {
        ^kubectl config view --flatten | save -f $new_config_path
    }
    
    # 3. Replace the old config
    mv -f $new_config_path $kube_config_path
    
    # 4. Clean up
    rm $temp_config
    
    print $"Successfully merged context ($host). You can switch to it with: kubectl config use-context ($host)"
}
