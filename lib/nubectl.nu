# Autocomplete for Kubernetes object types
def "nu-complete k8s-object-types" [] {
    ["pod" "deployment"]
}

# Autocomplete for Kubernetes namespaces
def "nu-complete k8s-namespaces" [] {
    ["all"] | append (
        ^kubectl get namespaces -o jsonpath='{.items[*].metadata.name}'
        | split row ' '
    )
}

# Pretty print events ordered by pod then by timestamp.
export def events [ 
    namespace: string@"nu-complete k8s-namespaces" = "all" # target namespace, defaults to all namespaces
] {
    let target_namespace = if $namespace == "all" { ["-A"] } else { ["-n" $namespace] }
    
    ^kubectl get events ...$target_namespace --field-selector involvedObject.kind=Pod --sort-by=.involvedObject.name -o go-template='{{range .items}}{{.lastTimestamp}}{{"»¦«"}}{{.type}}{{"»¦«"}}{{.reason}}{{"»¦«"}}{{.involvedObject.name}}{{"»¦«"}}{{.message}}{{"\n"}}{{end}}'
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
    
    let result_table = ^kubectl get pods ...$target_namespace -o go-template='{{range .items}}{{.metadata.namespace}}{{"»¦«"}}{{.metadata.name}}{{"»¦«"}}{{.status.phase}}{{"»¦«"}}{{.spec.nodeName}}{{"»¦«"}}{{.status.podIP}}{{"\n"}}{{end}}'
    | lines
    | skip 1
    | parse "{Namespace}»¦«{Name}»¦«{Status}»¦«{Node}»¦«{IP}"
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
    
    let result_table = ^kubectl get deployments ...$target_namespace -o go-template='{{range .items}}{{.metadata.namespace}}{{"»¦«"}}{{.metadata.name}}{{"»¦«"}}{{.spec.replicas}}{{"»¦«"}}{{.status.replicas}}{{"»¦«"}}{{.status.updatedReplicas}}{{"»¦«"}}{{.status.availableReplicas}}{{"\n"}}{{end}}'
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