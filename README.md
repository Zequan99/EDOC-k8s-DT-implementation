A simple example of Command-and-Control (C2) mitigating response applied with Kubernetes (K8s) and its extension - Cilium network policy.

# Synopsis

* Benign Pods are deployed on the K8s cluster, they regularly ping 8.8.8.8, which are considered as benign.
* When a Pod gets infected by malicious cron job, it also pings 1.1.1.1 to simulate malicious C2 communication.
* The goal is to realize the two D3FEND technique proposed in our paper (cf. Fig 4) for this use case. 
* Network traffic flows are observed with Cilium/Hubble, i.e., every ICMPV4 flow.
* All actions (administrative or security-related) are included in a Make file.

<img width="750" alt="image" src="https://github.com/user-attachments/assets/db808e1c-913b-4f96-b0ff-201f1f1ec684" />

# Configuration

## Python Prerequisites

```bash
pip install kubernetes fastapi uvicorn
```
## Launching the App

```bash
uvicorn api_server:app --host 0.0.0.0 --port 5000
```

then open your browser at the address: http://localhost:5000/static/index.html

# Demo
<img width="940" alt="image" src="https://github.com/user-attachments/assets/8c63ddb3-10c0-49b0-8a32-0e644362e36c" />
Once the Pod is infected, we observe pings sent to 1.1.1.1 from it.
<img width="937" alt="image" src="https://github.com/user-attachments/assets/25fba898-0b2c-4a88-b4f2-5134ac6287cc" />
When Network Traffic Filtering is applied, all traffic to and from the infected Pod is blocked.
When File Eviction is applied, no further traffic is generated.


https://github.com/user-attachments/assets/ef7920a6-91b1-41bf-ac7c-7ae855ae69aa

