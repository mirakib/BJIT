# Kubernetes Practical Assignment - Serial 11

This submission is for **Online Examination**.

| Setting | Value |
|---|---|
| Student serial | 11 |
| Application | `exampro` |
| Namespace | `exam-dev` |
| Deployment replicas | 3 |
| Container port | 8011 |
| NodePort | 30091 |
| StatefulSet replicas | 2 |

## 1. Prerequisites

Run these commands from the repository root (`BJIT`):

```powershell
kubectl version --client
kubectl cluster-info
kubectl get nodes
```

The cluster must have a default StorageClass for the PostgreSQL PVCs:

```powershell
kubectl get storageclass
```

If no StorageClass is available, enable or configure one for your Kubernetes distribution before deploying the StatefulSet.

## 2. Open the project directory

```powershell
cd "Project 01"
$manifestDir = "student-11-exampro"
```

The namespace manifest is `namespace.yaml`. The seven assignment manifests are in `student-11-exampro`.

## 3. Create the namespace

```powershell
kubectl apply -f .\namespace.yaml
kubectl get namespace exam-dev
```

All later commands use `-n exam-dev`.

## 4. Deploy the standalone Pod

```powershell
kubectl apply -f .\$manifestDir\01-pod.yaml
kubectl get pod student-11-exampro-pod -n exam-dev -w
```

Press `Ctrl+C` after the Pod reaches `Running`.

Inspect labels, ports, and resources:

```powershell
kubectl describe pod student-11-exampro-pod -n exam-dev
kubectl get pod student-11-exampro-pod -n exam-dev --show-labels
```

## 5. Deploy the application Deployment

```powershell
kubectl apply -f .\$manifestDir\02-deployment.yaml
kubectl rollout status deployment/student-11-exampro-deployment -n exam-dev
kubectl get deployment,pods -n exam-dev -l app=exampro -o wide
```

The Deployment starts with three replicas, as required for serial 11.

## 6. Demonstrate scaling

Scale from three to five replicas:

```powershell
kubectl scale deployment/student-11-exampro-deployment --replicas=5 -n exam-dev
kubectl rollout status deployment/student-11-exampro-deployment -n exam-dev
kubectl get deployment,pods -n exam-dev -l app=exampro
```

Restore the assigned replica count:

```powershell
kubectl scale deployment/student-11-exampro-deployment --replicas=3 -n exam-dev
kubectl rollout status deployment/student-11-exampro-deployment -n exam-dev
```

## 7. Demonstrate a rolling update

Update the image tag:

```powershell
kubectl set image deployment/student-11-exampro-deployment `
  exampro-web=nginx:1.27.1 -n exam-dev
kubectl rollout status deployment/student-11-exampro-deployment -n exam-dev
kubectl rollout history deployment/student-11-exampro-deployment -n exam-dev
```

To roll back:

```powershell
kubectl rollout undo deployment/student-11-exampro-deployment -n exam-dev
kubectl rollout status deployment/student-11-exampro-deployment -n exam-dev
```

## 8. Create and test the Services

This file creates both the application NodePort Service and the PostgreSQL headless Service:

```powershell
kubectl apply -f .\$manifestDir\03-service.yaml
kubectl get services -n exam-dev
kubectl describe service student-11-exampro-service -n exam-dev
kubectl describe service student-11-exampro-db-headless -n exam-dev
```

Confirm that the application Service has endpoints:

```powershell
kubectl get endpoints student-11-exampro-service -n exam-dev
```

The NodePort is `30091`. If the cluster is reachable at `localhost`, test it with:

```powershell
curl.exe http://localhost:30091
```

For Minikube, use:

```powershell
minikube service student-11-exampro-service -n exam-dev --url
```

For a remote cluster, replace `<node-ip>` with an eligible worker-node IP:

```powershell
curl.exe http://<node-ip>:30091
```

## 9. Deploy the PostgreSQL StatefulSet

The StatefulSet manifest creates the database Secret and two PostgreSQL replicas:

```powershell
kubectl apply -f .\$manifestDir\04-statefulset.yaml
kubectl rollout status statefulset/student-11-exampro-db -n exam-dev
kubectl get statefulset,pods,pvc -n exam-dev -l app=exampro-db
```

Verify predictable Pod names and individual PVCs:

```powershell
kubectl get pods -n exam-dev -l app=exampro-db
kubectl get pvc -n exam-dev -l app=exampro-db
```

Expected Pod names include:

```text
student-11-exampro-db-0
student-11-exampro-db-1
```

Delete one Pod and verify that Kubernetes recreates the same identity:

```powershell
kubectl delete pod student-11-exampro-db-0 -n exam-dev
kubectl get pods -n exam-dev -l app=exampro -w
```

Press `Ctrl+C` after `student-11-exampro-db-0` returns to `Running`. Confirm that its PVC remains:

```powershell
kubectl get pvc -n exam-dev
kubectl describe pvc postgres-data-student-11-exampro-db-0 -n exam-dev
```

## 10. Deploy the DaemonSet

```powershell
kubectl apply -f .\$manifestDir\05-daemonset.yaml
kubectl rollout status daemonset/student-11-exampro-node-agent -n exam-dev
kubectl get daemonset,pods -n exam-dev -l app=exampro-node-agent -o wide
```

There should be one DaemonSet Pod per eligible worker node. View the node hostname and heartbeat:

```powershell
kubectl logs -n exam-dev -l app=exampro-node-agent --tail=20
```

If the lab permits adding a worker node, run `kubectl get nodes -o wide` after it joins and verify that a new node-agent Pod is scheduled there.

## 11. Run the one-time Job

```powershell
kubectl apply -f .\$manifestDir\06-job.yaml
kubectl get jobs,pods -n exam-dev -l app=exampro-cleanup
kubectl wait --for=condition=complete job/student-11-exampro-cleanup -n exam-dev --timeout=120s
kubectl logs job/student-11-exampro-cleanup -n exam-dev
```

The logs must show the cleanup start time and completion message.

## 12. Deploy and verify the CronJob

```powershell
kubectl apply -f .\$manifestDir\07-cronjob.yaml
kubectl get cronjob student-11-exampro-scheduled-cleanup -n exam-dev
```

The schedule is every five minutes. Watch Jobs and wait for at least two scheduled runs:

```powershell
kubectl get cronjobs,jobs -n exam-dev -w
```

Press `Ctrl+C` after multiple Jobs exist. View a scheduled Job's logs:

```powershell
$scheduledJob = kubectl get jobs -n exam-dev `
  -l app=exampro-scheduled-cleanup `
  --sort-by=.metadata.creationTimestamp `
  -o jsonpath="{.items[-1].metadata.name}"
kubectl logs job/$scheduledJob -n exam-dev
```

## 13. Run the required verification commands

```powershell
kubectl get all -n exam-dev
kubectl get pods -n exam-dev -o wide
kubectl get deployments -n exam-dev
kubectl get services -n exam-dev
kubectl get statefulsets -n exam-dev
kubectl get daemonsets -n exam-dev
kubectl get jobs -n exam-dev
kubectl get cronjobs -n exam-dev
kubectl get pvc -n exam-dev
```

Useful additional checks:

```powershell
kubectl get secret student-11-exampro-db-credentials -n exam-dev
kubectl get events -n exam-dev --sort-by=.lastTimestamp
```

## 14. Screenshots for submission

Take screenshots showing:

1. The Pod in `Running` status.
2. Deployment replicas and completed rolling update.
3. NodePort Service and successful application response.
4. StatefulSet Pods with predictable names and both PVCs.
5. Recreated StatefulSet Pod after deletion.
6. DaemonSet Pods with node names from `-o wide`.
7. Job status `Complete` and its logs.
8. Multiple CronJob-created Jobs and scheduled maintenance logs.
9. The output of all commands in Section 13.

## 15. Troubleshooting

Check why a Pod is pending or restarting:

```powershell
kubectl describe pod <pod-name> -n exam-dev
kubectl logs <pod-name> -n exam-dev --previous
kubectl get events -n exam-dev --sort-by=.lastTimestamp
```

Check StatefulSet storage provisioning:

```powershell
kubectl get storageclass
kubectl describe pvc -n exam-dev
```

Check application Service selectors and endpoints:

```powershell
kubectl get pods -n exam-dev --show-labels
kubectl get endpoints student-11-exampro-service -n exam-dev
```

## 16. Optional cleanup

This removes the assignment resources and their namespace:

```powershell
kubectl delete -f .\$manifestDir\07-cronjob.yaml
kubectl delete -f .\$manifestDir\06-job.yaml
kubectl delete -f .\$manifestDir\05-daemonset.yaml
kubectl delete -f .\$manifestDir\04-statefulset.yaml
kubectl delete -f .\$manifestDir\03-service.yaml
kubectl delete -f .\$manifestDir\02-deployment.yaml
kubectl delete -f .\$manifestDir\01-pod.yaml
kubectl delete -f .\namespace.yaml
```

## 17. Create the ZIP submission

From inside `Project 01`, package the manifests, namespace file, and README:

```powershell
Compress-Archive -Path .\namespace.yaml, .\README.md, .\$manifestDir `
  -DestinationPath .\student-11-exampro.zip -Force
```

Add the screenshots to the ZIP before submitting it. The final archive should be named:

```text
student-11-exampro.zip
```
