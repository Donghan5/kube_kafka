#!/bin/bash

set -e

GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

log_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}
log_warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}
log_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

echo -e "${GREEN}Starting Minikube...${NC}"
minikube start --driver=docker --container-runtime=containerd --extra-config=kubelet.cgroup-driver=systemd

log_info "Checking prerequisites..."
if ! minikube status &> /dev/null; then
    log_warn "Minikube is not running."
    log_info "Deleting and restarting Minikube cluster (driver=docker, runtime=containerd)."
    minikube delete
    minikube start --driver=docker --container-runtime=containerd --extra-config=kubelet.cgroup-driver=systemd --memory=4g --cpus=2
else
    log_info "Minikube is already running. Using existing cluster."
fi
log_info "Minikube cluster is ready."


# --- 3단계: Strimzi Operator (CRD) 설치 ---

log_info "Attempting to create Kafka namespace..."
# 네임스페이스가 이미 있어도 오류를 내지 않고 넘어감
kubectl create namespace kafka --dry-run=client -o yaml | kubectl apply -f -

log_info "Deploying Strimzi Operator (Installing Kafka CRD)..."
kubectl apply -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka

log_info "Waiting until Strimzi Operator is ready..."
# set -e 로 인해 이 명령이 실패하면 스크립트가 중단됨
kubectl wait deployment/strimzi-cluster-operator --for=condition=Available --timeout=300s -n kafka
log_info "Strimzi Operator is ready."


# --- 4단계: Kafka 클러스터 및 앱 배포 ---

log_info "Deploying Kafka cluster (my-cluster)..."
kubectl apply -f kafka-cluster.yaml -n kafka

log_info "Deploying Producer application..."
kubectl apply -f producer.yaml -n kafka

log_info "Deploying Consumer application..."
kubectl apply -f consumer.yaml -n kafka


# --- 5단계: 배포 완료 및 확인 ---

log_info "All resources have been deployed."
log_warn "It may take 1-2 minutes for the Kafka cluster to fully start."
log_info "Streaming Consumer logs in real-time after 15 seconds..."

sleep 15

log_info "--- Consumer logs (Press Ctrl+C to stop) ---"
# Deployment 이름을 사용하면 Pod 이름을 몰라도 로그를 바로 추적할 수 있음
kubectl logs -f deployment/kafka-consumer -n kafka