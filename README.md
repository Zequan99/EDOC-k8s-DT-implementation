A simple example of Command-and-Control (C2) mitigating response applied with Kubernetes (K8s) and its extension - Cilium network policy.

# synopsis

* Benign Pods are deployed on the K8s cluster, they regularly ping 8.8.8.8, which are considered as benign.
* When a Pod gets infected by malicious cron job, it also pings 1.1.1.1 to simulate malicious C2 communication.
* The goal is to realize the two D3FEND technique proposed in our paper (cf. Fig 4) for this use case. 
* Network traffic flows are observed with Cilium/Hubble, i.e., every ICMPV4 flow.

<img width="750" alt="image" src="https://github.com/user-attachments/assets/39f60d59-25d2-48a1-8509-941f9c171012" />

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

