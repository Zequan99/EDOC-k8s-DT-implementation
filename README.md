simple example of a network policy applied with cilium.

First, some containers are deployed on the cluster, they regularly ping 8.8.8.8.
Then a container gets infected, it also ping 1.1.1.1.
Flows are observed with cilium/hubble, and every ICMPV4 flow is forwarded.
then a network policy is put in place to block traffic to 1.1.1.1.
Flows are observed again, flows to 1.1.1.1 are dropped.

https://github.com/user-attachments/assets/4e5fc87b-0422-4c89-bbbc-669223df1908

