# Canary lab
stable = html-app:v1 (9 pods)   canary = html-app:v2 (1 pod)  => roughly 10% of requests hit v2
Build a visibly different v2 and push it to ECR first.

1. Deploy:           kubectl apply -k .
2. Pods:             kubectl -n canary get pods -L track
3. URL:              kubectl -n canary get svc html-app
4. Test split:       for i in $(seq 1 30); do curl -s http://<NLB-DNS> | grep -i "<title>"; done | sort | uniq -c
5. Watch canary:     kubectl -n canary logs -l track=canary --tail=50
                     kubectl -n canary get pods -L track   (restarts? not Ready?)

## Increase canary traffic (e.g. 50/50)
kubectl -n canary scale deploy/html-app-canary --replicas=5
kubectl -n canary scale deploy/html-app-stable --replicas=5

## PROMOTE (canary is good): make stable run v2, then remove canary
kubectl -n canary set image deploy/html-app-stable html-app=430398381271.dkr.ecr.ap-southeast-2.amazonaws.com/statichtmlpages:v2
kubectl -n canary rollout status deploy/html-app-stable
kubectl -n canary scale deploy/html-app-canary --replicas=0

## ROLLBACK (canary is bad): one command
kubectl -n canary scale deploy/html-app-canary --replicas=0

## Clean up (deletes the NLB too)
kubectl delete -k .
