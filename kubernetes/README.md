# html-app Kubernetes manifests

## Structure
base/            shared manifests (Deployment, Service type LoadBalancer)
overlays/dev     1 replica, namespace dev
overlays/prod    HPA + PDB, bigger limits, namespace prod

## Before you start
1. ECR URI is set to statichtmlpages; update newTag in overlays/dev and overlays/prod per release.
2. Confirm container port in base/deployment.yaml (80 for plain nginx).
3. EKS nodes pull from ECR via the node IAM role (AmazonEC2ContainerRegistryReadOnly).

## Commands
kubectl kustomize overlays/dev            # preview rendered YAML
kubectl apply -k overlays/dev             # deploy dev
kubectl apply -k overlays/prod            # deploy prod
kubectl -n dev rollout status deploy/html-app
kubectl -n dev rollout history deploy/html-app
kubectl -n dev rollout undo deploy/html-app

## Release a new version
Push image with a new tag, edit newTag in the overlay, apply (later: Argo CD does this from Git).

## Access the app
kubectl -n dev get svc html-app   # EXTERNAL-IP column = NLB DNS name (takes 2-3 min)

Ingress is intentionally left out; it is the next learning step.
