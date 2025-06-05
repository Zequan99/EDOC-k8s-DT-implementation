# === Setup and Cleanup ===

setup: clean Deploy

clean: Undeploy Unisolate-nodes

Undeploy:
	@kubectl delete deployment.apps/ancile-malicious || true
	@kubectl delete deployment.apps/ancile-benign || true
	@kubectl delete ciliumnetworkpolicy.cilium.io/ancile-block-all-infected-pods || true
	@rm -f infected-pod.txt

Deploy:
	kubectl apply -f deployment-malicious.yaml
	kubectl apply -f deployment-bening.yaml
	kubectl apply -f ancile-default-policy.yaml

# === Infection ===

Infect:
	@TARGET=$$(kubectl get pods -l app=ancile-malicious -o json | \
		jq -r '.items[] | select(.status.phase == "Running" and (.metadata.deletionTimestamp == null)) | .metadata.name' | \
		shuf -n1); \
	echo "$$TARGET" > infected-pod.txt; \
	echo "Selected pod: $$TARGET"; \
	kubectl exec $$TARGET -- sh -c "ping 1.1.1.1 >> /var/log/cron.log 2>&1 &"

# === Observation ===

Observe:
	hubble observe --from-label app=ancile-malicious --protocol icmpv4

Observe-infected:
	@if [ -f infected-pod.txt ]; then \
		hubble observe --pod $$(cat infected-pod.txt) --protocol icmp; \
	else \
		echo "File 'infected-pod.txt' not found. Run 'make Infect' first."; \
	fi

Logs:
	kubectl logs  -l app=ancile-malicious --max-log-requests=10

Hubble:
	cilium hubble port-forward &
	hubble status

# Return infected nodes (one per line)
Get-infected-nodes:
	@hubble observe --protocol icmpv4 --to-ip 1.1.1.1 -o json | \
	jq -r '.flow | select(.source.pod_name and .source.workloads != null) | .source.pod_name' | \
	sort -u | \
	xargs -r -I{} sh -c 'kubectl get pod {} -o json 2>/dev/null' | \
	jq -r 'select(.status.phase == "Running") | .spec.nodeName' | \
	sort -u

# Return infected pods (one per line)
Get-infected-pods:
	@hubble observe --from-label app=ancile-malicious --protocol icmpv4 --to-ip 1.1.1.1 -o json | \
	jq -r '.flow.source.pod_name // empty' | \
	sort -u | \
	xargs -r -I{} sh -c 'kubectl get pod {} -o json 2>/dev/null' | \
	jq -r 'select(.status.phase == "Running") | .metadata.name' | \
	sort -u

# === Detection (silent for scripting) ===

_list-infected-pods:
	@for pod in $$(hubble observe --from-label app=ancile-malicious --protocol icmpv4 --to-ip 1.1.1.1 -o json | \
		jq -r '.flow.source.pod_name // empty' | sort -u); do \
		phase=$$(kubectl get pod $$pod -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound"); \
		if [ "$$phase" = "Running" ]; then echo $$pod; fi; \
	done

_list-infected-nodes:
	@hubble observe --protocol icmpv4 --to-ip 1.1.1.1 -o json | \
	jq -r '.flow | select(.source.pod_name and .source.workloads != null) | .source.pod_name' | \
	sort -u | \
	xargs -r -I{} sh -c 'kubectl get pod {} -o json 2>/dev/null' | \
	jq -r 'select(.status.phase == "Running") | .spec.nodeName' | sort -u

_list-infected-deployments:
	@hubble observe --protocol icmpv4 --to-ip 1.1.1.1 -o json | \
	jq -r '.flow | select(.source.pod_name and .source.workloads != null) | .source.pod_name' | \
	sort -u | \
	xargs -r -I{} sh -c 'kubectl get pod {} -o json 2>/dev/null' | \
	jq -r 'select(.status.phase == "Running") | .metadata.ownerReferences[] | select(.kind == "ReplicaSet") | .name' | \
	sed -E 's/-[a-z0-9]{9,}$$//' | sort -u

# === Labeling ===

Label-infected-pods:
	@echo "Labeling infected pods with ancile-status=infected..."; \
	for pod in $$(make --no-print-directory _list-infected-pods); do \
		echo "Labeling pod: $$pod"; \
		kubectl label pod $$pod ancile-status=infected --overwrite; \
	done

# === Isolation ===

Isolate-infected-pods: Label-infected-pods
	kubectl apply -f block-all-infected.yaml

Unisolate:
	kubectl delete ciliumnetworkpolicy.cilium.io/ancile-talks-world || true

Unisolate-nodes:
	@echo "Uncordoning all nodes..."; \
	for node in $$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do \
		kubectl uncordon $$node; \
	done

# === Eviction ===

process-kill-infected:
	@echo "Killing 'ping' process in infected pods..."; \
	for pod in $$(make --no-print-directory _list-infected-pods); do \
		echo "Processing pod: $$pod"; \
		kubectl exec $$pod -- pkill -f ping || echo "No ping process in $$pod"; \
	done

Evict-pods:
	@echo "Evicting infected pods..."; \
	for pod in $$(make --no-print-directory _list-infected-pods); do \
		kubectl delete pod $$pod || true; \
	done

Evict-deployments:
	@echo "Evicting infected deployments..."; \
	for deploy in $$(make --no-print-directory _list-infected-deployments); do \
		kubectl delete deployment $$deploy || true; \
	done

Evict-nodes:
	@echo "Evicting infected nodes..."; \
	for node in $$(make --no-print-directory _list-infected-nodes); do \
		kubectl cordon $$node; \
		kubectl drain $$node --ignore-daemonsets --delete-emptydir-data --force; \
	done

# === Interactive Dashboard ===

ibn:
	@bash -c '\
	BOLD="\\033[1m"; RESET="\\033[0m"; \
	echo "=== Threat Detection ==="; \
	echo -n "Working on your cluster..."; \
	for i in 1 2 3; do sleep 0.5; echo -n "."; done; echo ""; \
	infected_pods="$$(make --no-print-directory _list-infected-pods)"; \
	infected_nodes="$$(make --no-print-directory _list-infected-nodes)"; \
	infected_deployments="$$(make --no-print-directory _list-infected-deployments)"; \
	if [ -z "$$infected_pods" ] && [ -z "$$infected_nodes" ] && [ -z "$$infected_deployments" ]; then \
		echo "No infected assets detected. Cluster appears clean."; \
		exit 0; \
	fi; \
	echo ""; \
	echo "$${BOLD}Infected Pods:$${RESET}"; echo "$$infected_pods"; \
	echo "$${BOLD}Infected Nodes:$${RESET}"; echo "$$infected_nodes"; \
	echo "$${BOLD}Infected Deployments:$${RESET}"; echo "$$infected_deployments"; \
	echo ""; \
	echo "Choose an action:"; \
	select action in "Evict Pod" "Evict Deployment" "Evict Node" "Isolate Pod" "Isolate Node (not implemented)" "Isolate Deployment (not implemented)" "Exit"; do \
		case $$action in \
			"Evict Pod") \
				for pod in $$infected_pods; do \
					echo "Evicting pod: $$pod"; \
					kubectl delete pod $$pod || true; \
				done; break ;; \
			"Evict Deployment") \
				for deploy in $$infected_deployments; do \
					echo "Evicting deployment: $$deploy"; \
					kubectl delete deployment $$deploy || true; \
				done; break ;; \
			"Evict Node") \
				for node in $$infected_nodes; do \
					echo "Cordoning node: $$node"; \
					kubectl cordon $$node || true; \
					echo "Draining node: $$node"; \
					kubectl drain $$node --ignore-daemonsets --delete-emptydir-data --force || true; \
				done; break ;; \
			"Isolate Pod") \
				make Isolate-infected-pods && break ;; \
			"Isolate Node (not implemented)") \
				echo "Isolate Node is not implemented yet."; break ;; \
			"Isolate Deployment (not implemented)") \
				echo "Isolate Deployment is not implemented yet."; break ;; \
			"Exit") break ;; \
			*) echo "Invalid option" ;; \
		esac; \
	done'

