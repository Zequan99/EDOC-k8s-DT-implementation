simple example of a network policy applied with cilium.

# synopsis

* First, some containers are deployed on the cluster, they regularly ping 8.8.8.8.
* Then a container gets infected by malicious cron job, it also pings 1.1.1.1.
* Flows are observed with cilium/hubble, and every ICMPV4 flow is forwarded.
* then we can Isolate or Evict things like infected pod, infected deployment or nodes containing infected pods.

# configuration

## python prerequisites

```bash
pip install kubernetes fastapi uvicorn
```
## launching the app

```bash
uvicorn api_server:app --host 0.0.0.0 --port 5000
```

then open your browser at the address: http://localhost:5000/static/index.html

# demo
<img width="940" alt="image" src="https://github.com/user-attachments/assets/8c63ddb3-10c0-49b0-8a32-0e644362e36c" />
Once the Pod is infected, we observe pings sent to 1.1.1.1 from it.
<img width="937" alt="image" src="https://github.com/user-attachments/assets/25fba898-0b2c-4a88-b4f2-5134ac6287cc" />
When Network Traffic Filtering is applied, all traffic to and from the infected Pod is blocked.
When File Eviction is applied, no further traffic is generated.


https://github.com/user-attachments/assets/ef7920a6-91b1-41bf-ac7c-7ae855ae69aa

