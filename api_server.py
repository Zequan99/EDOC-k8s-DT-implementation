from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from kubernetes import client, config
import subprocess

app = FastAPI()

# Allow CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from fastapi.staticfiles import StaticFiles

app.mount("/static", StaticFiles(directory="static", html=True), name="static")


def run_make(target: str) -> list[str]:
    result = subprocess.run(["make", "--no-print-directory", target], text=True, capture_output=True)
    return result.stdout.strip().splitlines()

# Load kubeconfig explicitly
config.load_kube_config(config_file="/etc/rancher/k3s/k3s.yaml")

core_v1 = client.CoreV1Api()
apps_v1 = client.AppsV1Api()

#def run_make(target: str) -> str:
#    result = subprocess.run(["make", target], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
#    return result.stdout


@app.delete("/process/infected")
def kill_infected_processes():
    output = run_make("process-kill-infected")
    return {"result": output}

@app.get("/pods")
def list_pods():
    infected = set(run_make("Get-infected-pods"))
    print(infected)
    pods =core_v1.list_namespaced_pod(namespace="default")
    output = []
    for pod in pods.items:
        name = pod.metadata.name
        phase = pod.status.phase
        deletion = pod.metadata.deletion_timestamp
        if phase == "Running" and not deletion:
            mark = " *" if name in infected else ""
            output.append(f"{name}{mark}")
    return output

@app.get("/nodes")
def list_nodes():
    infected = set(run_make("Get-infected-nodes"))
    nodes =core_v1.list_node()
    output = []
    for node in nodes.items:
        name = node.metadata.name
        unschedulable = node.spec.unschedulable
        conditions = node.status.conditions or []
        ready = any(c.type == "Ready" and c.status == "True" for c in conditions)
        if ready and not unschedulable:
            mark = " *" if name in infected else ""
            output.append(f"{name}{mark}")
    return output

@app.get("/deployments")
def get_deployments():
    deployments = apps_v1.list_namespaced_deployment(namespace="default")
    return [deploy.metadata.name for deploy in deployments.items]

@app.post("/experiment")
def setup():
    return run_make("setup")

@app.delete("/experiment")
def clean():
    return run_make("clean")

@app.post("/deployment")
def deploy():
    return run_make("Deploy")

@app.delete("/deployment")
def undeploy():
    return run_make("Undeploy")

@app.post("/attack")
def infect():
    return run_make("Infect")

@app.get("/network/logs")
def observe():
    return run_make("Observe")[:-10:-1]

@app.get("/network/logs/infected")
def observe_infected():
    return run_make("Observe-infected")

@app.get("/pods/logs")
def logs():
    return run_make("Logs")

@app.post("/experiment/hubble")
def hubble():
    return run_make("Hubble")

@app.post("/pods/infected/label")
def label_infected_pods():
    return run_make("Label-infected-pods")

@app.post("/pods/infected/isolation")
def isolate_infected_pods():
    return run_make("Isolate-infected-pods")

@app.delete("/pods/infected/isolation")
def unisolate():
    return run_make("Unisolate")

@app.delete("/nodes/infected/isolation")
def unisolate_nodes():
    return run_make("Unisolate-nodes")

@app.delete("/pods/infected")
def evict_pods():
    return run_make("Evict-pods")

@app.delete("/deployments/infected")
def evict_deployments():
    return run_make("Evict-deployments")

@app.delete("/nodes/infected")
def evict_nodes():
    return run_make("Evict-nodes")

