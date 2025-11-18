# Pretty print events ordered by pod then by timestamp.
export def events [ 
    namespace: string = "all" # target namespace, defaults to all namespaces
] {
    let target_namespace = if $namespace == "all" { ["-A"] } else { ["-n" $namespace] }
    
    ^kubectl get events ...$target_namespace --field-selector involvedObject.kind=Pod --sort-by=.involvedObject.name -o go-template='{{range .items}}{{.lastTimestamp}}{{"»¦«"}}{{.type}}{{"»¦«"}}{{.reason}}{{"»¦«"}}{{.involvedObject.name}}{{"»¦«"}}{{.message}}{{"\n"}}{{end}}'
    | lines
    | skip 1
    | parse "{Time}»¦«{Type}»¦«{Reason}»¦«{Pod}»¦«{Message}"
}

# List pods.
export def pods [
    namespace: string = "all" # target namespace, defaults to all namespaces
] {
    let target_namespace = if $namespace == "all" { ["-A"] } else { ["-n" $namespace] }
    
    ^kubectl get pods ...$target_namespace -o go-template='{{range .items}}{{.metadata.name}}{{"»¦«"}}{{.status.phase}}{{"»¦«"}}{{.spec.nodeName}}{{"»¦«"}}{{.status.podIP}}{{"\n"}}{{end}}'
    | lines
    | skip 1
    | parse "{Name}»¦«{Status}»¦«{Node}»¦«{IP}"
}

# List deployments.
export def deployments [
    namespace: string = "all" # target namespace, defaults to all namespaces
] {
    let target_namespace = if $namespace == "all" { ["-A"] } else { ["-n" $namespace] }
    
    ^kubectl get deployments ...$target_namespace -o go-template='{{range .items}}{{.metadata.name}}{{"»¦«"}}{{.spec.replicas}}{{"»¦«"}}{{.status.replicas}}{{"»¦«"}}{{.status.updatedReplicas}}{{"»¦«"}}{{.status.availableReplicas}}{{"\n"}}{{end}}'
    | lines
    | skip 1
    | parse "{Name}»¦«{Desired}»¦«{Current}»¦«{Updated}»¦«{Available}"
}