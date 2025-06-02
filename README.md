simple example of a network policy applied with cilium.

# synopsis

* First, some containers are deployed on the cluster, they regularly ping 8.8.8.8.
* Then a container gets infected, it also ping 1.1.1.1.
* Flows are observed with cilium/hubble, and every ICMPV4 flow is forwarded.
* then we can Isolate or Evict things like infected pod, infected deployment or nodes containing infected pods.

# reference target to the makefile
* setup: create all the resources for the demo
* clean: remove all the resources for the demo
* ibn: interractive mitigation policy engine
* Undeploy: remove the demo deployments
* Deploy: publish the deployments and default policy (allow all)
* Infect: infect a random pod, so that suspicious traffic comes from it
* Observe: show the flows from the pods
* Observe-infected: show the flows from the infected pods
* Logs: show the logs on the pods
* Hubble: create hubble resources so that we can watch the flows
* Label-infected-pods: put a 'infected" label to the infected pods
* Isolate-infected-pods: Label-infected-pods: block egress and ingress on the infected pods
* Unisolate-nodes: allow deployment on nodes that are cordonned
* Evict-pods: remove pods that are infected
* Evict-deployments: remove any deployment with an infected pod
* Evict-nodes: remove any node that contains an infected pod from the cluster


# demo

<iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/JfrrDT2bZFs?si=QJIXUtoHJSy_Aoxs" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
