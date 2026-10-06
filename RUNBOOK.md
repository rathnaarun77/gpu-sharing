# Demo flow
kubectl apply -f demo/01-whole-gpu.yaml
kubectl apply -f demo/02-fraction.yaml
kubectl apply -f demo/03-gpu-memory.yaml

# Where did pods land / which GPU they share
kubectl get pods -o wide
kubectl get pods -n kai-resource-reservation -o wide   # 1 reservation pod per shared GPU
kubectl get pod <frac-pod> -o jsonpath='{.metadata.annotations}' | jq

# Cluster-level GPU accounting
kubectl describe node gpu-lab-worker | grep -A6 Allocated

# Metrics (Prometheus / Grafana -> GPU folder -> DCGM dashboard)
DCGM_FI_DEV_GPU_UTIL
DCGM_FI_DEV_FB_USED
count by (node) (DCGM_FI_DEV_GPU_UTIL)

# Scale sharing live
kubectl scale deploy frac-half --replicas=8
