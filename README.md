A simple example of Command-and-Control (C2) mitigating response applied with Kubernetes (K8s) and its extension - Cilium network policy.

# Synopsis

* Benign Pods are deployed on the K8s cluster, they regularly ping 8.8.8.8, which is considered benign.
* When a Pod gets infected by a malicious cron job, it also pings 1.1.1.1 to simulate malicious C2 communication.
* The goal is to implement the two security intents proposed in our paper (cf. Fig 4) for this use case. 
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

then open your browser at the address: http://localhost:5000

# Demo
* Once the App is deployed, we can access the adminisration panel.

<img width="700" alt="image" src="https://github.com/user-attachments/assets/f79bef25-9070-4526-806c-2112f11e0170" /><br><br>

* Click on "Deploy" to set up the K8s cluster with 8 Pods, with 4 of them marked each with malicious label. We can check the deployed Pods using "Get Pods". 

<img width="700" alt="image" src="https://github.com/user-attachments/assets/6f258c1b-b5a5-4892-a03c-47b79bcfe038" /><br><br>

* Note that the malicious label only sets target for latter infection - at this step no Pod is infected. We can verify this by clicking on "Observe", remind that traffic to 8.8.8.8 is benign.

<img width="700" alt="image" src="https://github.com/user-attachments/assets/8b27a343-d54a-4778-8841-28f0a9313579" /><br><br>

* Click on "Infect" to randomly infect one Pod with malicious label. Once a Pod is infected, it sends pings sent to 1.1.1.1 every minute. We can verify this using "Observe".

<img width="700" alt="image" src="https://github.com/user-attachments/assets/8c63ddb3-10c0-49b0-8a32-0e644362e36c" /><br><br>

* To mitigate the malicious C2 communication, we apply the two security intents with "Network Traffic Filtering" and "File Eviction" as D3FEND technique (cf. https://d3fend.mitre.org/) respectively.

* Network Traffic Filtering: With Cilium network policy, all outbound traffic from the infected Pod is blocked.

<img width="700" alt="image" src="https://github.com/user-attachments/assets/25fba898-0b2c-4a88-b4f2-5134ac6287cc" /><br><br>

* File Eviction: By removing the malicious cron job, no further traffic is generated from the infected Pod.<br><br>

* Watch the below video demonstration for more details:

https://github.com/user-attachments/assets/ef7920a6-91b1-41bf-ac7c-7ae855ae69aa

