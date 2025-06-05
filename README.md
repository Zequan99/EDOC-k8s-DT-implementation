simple example of a network policy applied with cilium.

# synopsis

* First, some containers are deployed on the cluster, they regularly ping 8.8.8.8.
* Then a container gets infected, it also ping 1.1.1.1.
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

https://github.com/user-attachments/assets/ef7920a6-91b1-41bf-ac7c-7ae855ae69aa

