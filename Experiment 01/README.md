# Experiment 01: Basic Kubernetes Deployment and Service

This experiment demonstrates the basic Kubernetes objects used to run and
expose a small web application:

- Two `Deployment` objects (`v1` and `v2`)
- Two NGINX Pods managed by each Deployment
- A `NodePort` `Service` named `web`
- Resource requests and limits for each container
- Basic Kubernetes inspection and verification commands

The containers serve a small HTML page generated when each container starts.
The `v1` Deployment displays **Moshrekul Islam Deployment** and the `v2`
Deployment displays **Sujoy Sadhu Deployment**.

## Scenario

A team is running two versions of a simple web workload in Kubernetes. Each
version is represented by a Deployment so Kubernetes can keep the requested
number of Pods running and recreate Pods when they fail. A Service provides a
stable network endpoint for the workload instead of requiring clients to
connect directly to changing Pod IP addresses.

This is intentionally a small, local-cluster experiment. It focuses on the
relationship between Deployments, Pods, labels, selectors, and Services.

## Objectives

By completing this experiment, you should be able to:

1. Apply Kubernetes YAML manifests to a cluster.
2. Explain how a Deployment creates and manages ReplicaSets and Pods.
3. Confirm that the desired number of replicas are running.
4. Understand how labels and selectors connect a Service to Pods.
5. Access an NGINX workload through `port-forward` or a `NodePort`.
6. Inspect logs, endpoints, events, and rollout status.
7. Remove the experiment cleanly from the cluster.

## Files

| File | Purpose |
| --- | --- |
| `01-deployment.yaml` | Creates Deployment `v1` with two NGINX replicas |
| `02-deployment.yaml` | Creates Deployment `v2` with two NGINX replicas |
| `service.yaml` | Creates the `web` NodePort Service on port `30080` |

## Prerequisites

Use any Kubernetes cluster that supports `apps/v1` Deployments and
`v1` Services. For a local experiment, suitable choices include:

- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- [Docker Desktop Kubernetes](https://docs.docker.com/desktop/features/kubernetes/)
- [MicroK8s](https://microk8s.io/docs)

Install and configure `kubectl`, then verify that it can reach the cluster:

```bash
kubectl version --client
kubectl cluster-info
```

If you use Minikube, start it first:

```bash
minikube start
```

## Important selector check

The current manifests contain a selector mismatch:

- Pods created by both Deployments have the label `app: web`.
- `service.yaml` currently selects `app: v1`.

As written, the Service will have no matching endpoints. The Deployments can
still be tested directly, but Service requests will not reach a Pod. To make
the Service route to the Pods, change its selector to:

```yaml
selector:
  app: web
```

After making that change, apply `service.yaml` again. Because both
Deployments use `app: web`, the Service can route to Pods from either
Deployment. This is useful for demonstrating label-based selection, but it is
not version-specific traffic routing.

## Execute the experiment

Run these commands from the `Experiment 01` directory:

```bash
cd "Experiment 01"

kubectl apply -f 01-deployment.yaml
kubectl apply -f 02-deployment.yaml
kubectl apply -f service.yaml
```

If you applied the Service before correcting its selector, update it after
the correction:

```bash
kubectl apply -f service.yaml
```

The manifests use the `default` namespace. To use a separate namespace,
create it and add `-n <namespace>` to every command:

```bash
kubectl create namespace experiment-01
kubectl apply -n experiment-01 -f 01-deployment.yaml
kubectl apply -n experiment-01 -f 02-deployment.yaml
kubectl apply -n experiment-01 -f service.yaml
```

## Test and verify

### 1. Check Deployments and Pods

```bash
kubectl get deployments
kubectl get replicasets
kubectl get pods -o wide
```

Expected result:

- Deployment `v1` reports `2/2` ready replicas.
- Deployment `v2` reports `2/2` ready replicas.
- Four Pods are in the `Running` state.

Wait for the rollout if necessary:

```bash
kubectl rollout status deployment/v1
kubectl rollout status deployment/v2
```

### 2. Inspect labels and Service endpoints

```bash
kubectl get pods --show-labels
kubectl get service web
kubectl get endpoints web
kubectl describe service web
```

After correcting the selector, `kubectl get endpoints web` should show Pod
IP addresses on port `80`. If it shows `<none>`, check that the Service
selector exactly matches the labels on the Pods.

For newer Kubernetes versions, EndpointSlices can also be inspected:

```bash
kubectl get endpointslice -l kubernetes.io/service-name=web
```

### 3. Test project


Keep that command running in one terminal and use another terminal:

```bash
curl http://localhost:8080
```


The response should contain either the `v1` or `v2` deployment message when
the Service selector is `app: web`.

### 4. Test the NodePort

The Service exposes port `80` through NodePort `30080`:

```bash
kubectl get service web
```

For Minikube:

```bash
minikube service web --url
```

Use the printed URL with `curl`. For a cluster whose node is reachable
directly:

```bash
curl http://<node-ip>:30080
```

If the Service selector has not been corrected, this request will fail or
return no application response because the Service has no endpoints.

### 5. Inspect application output and events

List the Pods and view logs from one of them:

```bash
kubectl get pods -l app=web
kubectl logs <pod-name>
```

Inspect a Deployment or Pod when troubleshooting:

```bash
kubectl describe deployment v1
kubectl describe pod <pod-name>
kubectl get events --sort-by=.lastTimestamp
```

### 6. Verify self-healing

Choose a Pod, delete it, and watch Kubernetes create a replacement:

```bash
kubectl delete pod <pod-name>
kubectl get pods -w
```

Press `Ctrl+C` after the replacement Pod becomes `Running`. The Deployment
should return to two ready replicas.

## Cleanup

Delete the resources created by this experiment:

```bash
kubectl delete -f service.yaml
kubectl delete -f 02-deployment.yaml
kubectl delete -f 01-deployment.yaml
```

If you used the dedicated namespace instead:

```bash
kubectl delete namespace experiment-01
```

## Lessons learned

- A Deployment declares the desired state; Kubernetes continuously works to
  keep that state, including replacing failed Pods.
- A Deployment does not provide a stable client endpoint. A Service provides
  that stable virtual IP and DNS name.
- Service selectors match Pod labels, not Deployment names. A selector that
  does not match the Pod template labels produces a Service with no
  endpoints.
- Labels should be designed intentionally. Using the same `app: web` label
  for both versions makes one Service load-balance across both versions.
- `port-forward` is convenient for local testing, while `NodePort` exposes a
  port on each cluster node.
- Resource requests help Kubernetes schedule Pods; limits cap their CPU and
  memory usage.
- Pod IP addresses are temporary. Clients should use the Service rather than
  storing Pod IPs.

## Suggested follow-up experiments

1. Give the Deployments distinct labels such as `app: web, version: v1` and
   `app: web, version: v2`, then route the Service to only one version.
2. Change the NGINX image tag and run `kubectl rollout status` to observe a
   rolling update.
3. Scale one Deployment:

   ```bash
   kubectl scale deployment/v1 --replicas=3
   kubectl get pods -l app=web
   ```

4. Add readiness and liveness probes and observe how they affect traffic and
   replacement behavior.