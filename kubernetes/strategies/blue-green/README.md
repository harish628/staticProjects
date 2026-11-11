# Blue/Green lab
blue  = html-app:v1 (live)      green = html-app:v2 (new)
Build a visibly different v2 (e.g. change the page heading), push it to ECR first.

1. Deploy everything:      kubectl apply -k .
2. Check pods:             kubectl -n bluegreen get pods --show-labels
3. Live URL (blue):        kubectl -n bluegreen get svc html-app
4. Test green privately:   kubectl -n bluegreen port-forward svc/html-app-preview 8080:80
                           open http://localhost:8080
5. SWITCH to green:
   kubectl -n bluegreen patch svc html-app -p '{"spec":{"selector":{"app.kubernetes.io/name":"html-app","version":"green"}}}'
6. ROLLBACK to blue:
   kubectl -n bluegreen patch svc html-app -p '{"spec":{"selector":{"app.kubernetes.io/name":"html-app","version":"blue"}}}'
7. After green is stable, scale blue down: kubectl -n bluegreen scale deploy/html-app-blue --replicas=0
8. Clean up (deletes the NLB too): kubectl delete -k .
