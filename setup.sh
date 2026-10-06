#!/usr/bin/env bash
set -euo pipefail
# Pin versions if you want: FGO_VERSION=0.0.xx KAI_VERSION=v0.x.y ./setup.sh
FGO_VER=${FGO_VERSION:+--version $FGO_VERSION}
KAI_VER=${KAI_VERSION:+--version $KAI_VERSION}

kind create cluster --config kind-config.yaml

# 1. Monitoring first (CRDs needed by others)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade -i kps prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace -f monitoring-values.yaml --wait

# 2. Fake GPU operator (device plugin + fake DCGM exporter + util simulator)
helm upgrade -i gpu-operator oci://ghcr.io/run-ai/fake-gpu-operator/fake-gpu-operator \
  -n gpu-operator --create-namespace -f fake-gpu-values.yaml $FGO_VER --wait

# 3. KAI scheduler with GPU sharing (fractions / gpu-memory)
helm upgrade -i kai-scheduler oci://ghcr.io/nvidia/kai-scheduler/kai-scheduler \
  -n kai-scheduler --create-namespace --set global.gpuSharing=true $KAI_VER --wait

kubectl apply -f demo/00-queues.yaml

echo "--- GPU capacity per node ---"
kubectl get nodes -o custom-columns='NODE:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu,PRODUCT:.metadata.labels.nvidia\.com/gpu\.product'
echo "Grafana: kubectl -n monitoring port-forward svc/kps-grafana 3000:80  (admin/admin)"
