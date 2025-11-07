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
if ! minikube status &> /dev/null; then
    log_warn "Minikube is not running."
    log_info "Deleting and restarting Minikube cluster (driver=docker, runtime=containerd)."
    minikube delete
    minikube start --driver=docker --container-runtime=containerd --extra-config=kubelet.cgroup-driver=systemd --memory=4g --cpus=2
else
    log_info "Minikube is already running. Using existing cluster."
fi
log_info "Minikube cluster is ready."

log_info "Enabling Minikube Ingress addon..."
minikube addons enable ingress

log_info "Attempting to create Kafka namespace..."
kubectl create namespace kafka --dry-run=client -o yaml | kubectl apply -f -

log_info "Deploying Strimzi Operator (Installing Kafka CRD)..."
kubectl apply -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka

log_info "Waiting until Strimzi Operator is ready..."
kubectl wait deployment/strimzi-cluster-operator --for=condition=Available --timeout=300s -n kafka
log_info "Strimzi Operator is ready."

log_info "Deploying Kafka cluster (my-cluster)..."
kubectl apply -f kafka/kafka-cluster.yaml -n kafka

log_info "Deploying Producer application..."
kubectl apply -f kafka/producer.yaml -n kafka

log_info "Deploying Consumer application..."
kubectl apply -f kafka/consumer.yaml -n kafka

log_info "Deploying PostgreSQL Secret..."
kubectl apply -f postgres/postgres-secret.yaml -n kafka

log_info "Deploying PostgreSQL StatefulSet..."
kubectl apply -f postgres/postgres-deployment.yaml -n kafka

log_info "Deploying WebApp (for Rollout tests)..."
kubectl apply -f webapp/webapp.yaml -n kafka

log_info "Deploying Ingress rule for WebApp..."
kubectl apply -f webapp/webapp-ingress.yaml -n kafka

log_info "All resources have been deployed."
log_warn "It may take 1-2 minutes for the Kafka cluster and PostgreSQL to fully start."
log_info "Run 'minikube ip' to get your cluster IP. Access http://<MINIKUBE_IP>/ to see the webapp."
log_info "Streaming Consumer logs in real-time after 15 seconds..."

sleep 15

log_info "--- Consumer logs (Press Ctrl+C to stop) ---"
kubectl logs -f deployment/kafka-consumer -n kafka