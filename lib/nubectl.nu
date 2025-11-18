export def events [ 
    namespace: string = "all" 
] {
    let target_namespace = if $namespace == "all" { ["-A"] } else { ["-n" $namespace] }
    
    ^kubectl get events ...$target_namespace --field-selector involvedObject.kind=Pod --sort-by=.involvedObject.name -o go-template='{{range .items}}{{.lastTimestamp}}{{"»¦«"}}{{.type}}{{"»¦«"}}{{.reason}}{{"»¦«"}}{{.involvedObject.name}}{{"»¦«"}}{{.message}}{{"\n"}}{{end}}'
    | lines
    | skip 1
    | parse "{Time}»¦«{Type}»¦«{Reason}»¦«{Pod}»¦«{Message}"
}