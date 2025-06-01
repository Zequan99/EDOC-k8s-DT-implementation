clean: undeploy unblock

infect:
	@TARGET=$$(kubectl get pods -l app=ancile-malicious -o json | \
		jq -r '.items[] | select(.status.phase == "Running" and (.metadata.deletionTimestamp == null)) | .metadata.name' | \
		shuf -n1); \
	echo "$$TARGET" > infected-pod.txt; \
	echo "Selected pod: $$TARGET"; \
	kubectl exec $$TARGET -- sh -c "ping 1.1.1.1 >> /var/log/cron.log 2>&1 &"

observe:
	hubble observe --from-label app=ancile-malicious --protocol icmpv4

observe-infected:
	@if [ -f infected-pod.txt ]; then \
		hubble observe --pod $$(cat infected-pod.txt) --protocol icmp; \
	else \
		echo "File 'infected-pod.txt' not found. Run 'make infect' first."; \
	fi

exec:
	kubectl exec -ti $$(kubectl get pods -l app=ancile-malicious -o jsonpath='{.items[*].metadata.name}' | \
		tr ' ' '\n' | shuf -n1) -- sh

undeploy:
	@kubectl delete deployment.apps/ancile-malicious || true
	@rm -f infected-pod.txt

deploy:
	kubectl apply -f deployment-malicious.yaml

unblock:
	kubectl delete ciliumnetworkpolicy.cilium.io/ancile-talks-world || true

block:
	kubectl apply -f block-ip-cilium.yaml

logs:
	kubectl logs -f -l app=ancile-malicious --max-log-requests=10

hubble:
	cilium hubble port-forward &
	hubble status

