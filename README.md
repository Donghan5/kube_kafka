# Kubernetes Kafka Demo Project

This project demonstrates a complete Kubernetes deployment setup featuring Apache Kafka message streaming, PostgreSQL database, and a web application, all running on Minikube with automated deployment scripts.

## Project Overview

This is a hands-on Kubernetes project that showcases:

- **Apache Kafka Cluster**: Message streaming platform using Strimzi operator
  - Producer application that generates timestamped messages every 10 seconds
  - Consumer application that reads and displays messages from the Kafka topic
- **PostgreSQL Database**: StatefulSet deployment with persistent storage
- **Web Application**: Nginx-based demo application accessible via Ingress
- **Infrastructure**: Managed by Minikube with Ingress addon enabled

## Architecture

The project deploys the following components in a dedicated `kafka` namespace:

1. **Strimzi Kafka Operator**: Manages Kafka cluster lifecycle
2. **Kafka Cluster** (`my-cluster`): 1 replica Kafka broker with ZooKeeper
3. **Kafka Producer**: Sends "Hello Kafka" messages with timestamps to the `logs` topic
4. **Kafka Consumer**: Consumes and displays messages from the `logs` topic
5. **PostgreSQL StatefulSet**: Database with persistent volume claim (1Gi storage)
6. **WebApp Deployment**: 3 replicas of nginx demo application
7. **Ingress Controller**: Routes external traffic to the web application

## Prerequisites

Before running this project, ensure you have the following installed:

- [Docker](https://docs.docker.com/get-docker/)
- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Make (optional, for using Makefile commands)

## Quick Start

### Option 1: Using the Deploy Script

The easiest way to deploy everything:

```bash
./deploy_all.sh
```

This script will:
1. Start Minikube (if not running) with Docker driver and containerd runtime
2. Enable Ingress addon
3. Create the `kafka` namespace
4. Deploy Strimzi Kafka operator
5. Deploy all Kafka, PostgreSQL, and WebApp resources
6. Stream consumer logs to your terminal

### Option 2: Using Makefile

```bash
# Deploy all resources
make deploy

# View rollout status
make rollout-check

# Rollback webapp deployment
make rollback

# Clean up (delete kafka namespace)
make clean

# Clean up everything (delete Minikube cluster)
make fclean
```

## Accessing the Application

After deployment completes:

1. Get your Minikube IP:
   ```bash
   minikube ip
   ```

2. Access the web application in your browser:
   ```
   http://<MINIKUBE_IP>/
   ```

## Monitoring

### View Kafka Consumer Logs

The deploy script automatically streams consumer logs. To manually view them:

```bash
kubectl logs -f deployment/kafka-consumer -n kafka
```

You should see messages like:
```
Hello Kafka time: Thu Nov  7 10:30:45 UTC 2025
Hello Kafka time: Thu Nov  7 10:30:55 UTC 2025
```

### View Kafka Producer Logs

```bash
kubectl logs -f deployment/kafka-producer -n kafka
```

### Check All Pods

```bash
kubectl get pods -n kafka
```

### View Services

```bash
kubectl get svc -n kafka
```

## Deployment Details

### Kafka Configuration

- **Cluster Name**: my-cluster
- **Kafka Replicas**: 1
- **ZooKeeper Replicas**: 1
- **Storage Type**: Ephemeral (data is lost on pod restart)
- **Listener**: Plain (non-TLS) on port 9092
- **Topic**: logs (created automatically by producer)

### PostgreSQL Configuration

- **Deployment Type**: StatefulSet
- **Image**: postgres:14.1
- **Storage**: 1Gi PersistentVolumeClaim
- **Service Type**: Headless (ClusterIP: None)
- **Port**: 5432
- **Credentials**: Stored in `postgres-secret.yaml`

### WebApp Configuration

- **Deployment Type**: Deployment
- **Replicas**: 3
- **Image**: nginxdemos/hello:plain-text
- **Port**: 80
- **Ingress**: Root path (/) routing

## Rollout Management

### Test Rollout Update

To test a deployment rollout, you can modify the webapp image:

```bash
kubectl set image deployment/webapp webapp=nginxdemos/hello:0.3 -n kafka
```

### Check Rollout Status

```bash
make rollout-check
# OR
kubectl rollout status deployment/webapp -n kafka
```

### Rollback Deployment

```bash
make rollback
# OR
kubectl rollout undo deployment/webapp -n kafka
```

### View Rollout History

```bash
kubectl rollout history deployment/webapp -n kafka
```

## Cleanup

### Remove All Resources (Keep Minikube)

```bash
make clean
# OR
kubectl delete namespace kafka
```

### Remove Everything Including Minikube

```bash
make fclean
# OR
minikube delete
```

## Resource Configuration

### Minikube Settings

- **Driver**: Docker
- **Container Runtime**: containerd
- **Memory**: 4GB
- **CPUs**: 2
- **Cgroup Driver**: systemd

## Troubleshooting

### Strimzi Operator Not Ready

If the Strimzi operator fails to start, check the logs:

```bash
kubectl logs deployment/strimzi-cluster-operator -n kafka
```

### Kafka Cluster Not Starting

Wait a few minutes (typically 1-2 minutes) for the Kafka cluster to fully initialize:

```bash
kubectl get kafka -n kafka
kubectl get pods -n kafka -w
```

### Consumer Not Receiving Messages

Ensure the producer is running and the topic exists:

```bash
kubectl get pods -n kafka | grep producer
kubectl exec -it deployment/kafka-producer -n kafka -- bin/kafka-topics.sh --list --bootstrap-server my-cluster-kafka-bootstrap.kafka:9092
```

### Ingress Not Working

Verify Ingress addon is enabled:

```bash
minikube addons list | grep ingress
```

Check Ingress resource:

```bash
kubectl get ingress -n kafka
kubectl describe ingress webapp-ingress -n kafka
```

## Project Structure

```
.
├── deploy_all.sh                 # Main deployment script
├── Makefile                      # Build automation
├── README.md                     # This file
├── kafka/
│   ├── kafka-cluster.yaml       # Kafka cluster definition
│   ├── producer.yaml            # Kafka producer deployment
│   └── consumer.yaml            # Kafka consumer deployment
├── postgre/
│   ├── postgres-secret.yaml     # PostgreSQL credentials
│   └── postgres-deployment.yaml # PostgreSQL StatefulSet
└── webapp/
    ├── webapp.yaml              # WebApp deployment & service
    └── webapp-ingress.yaml      # Ingress configuration
```

## Learning Objectives

This project demonstrates:

- Kubernetes operators (Strimzi)
- StatefulSet vs Deployment patterns
- Message streaming with Kafka
- Persistent storage with PVCs
- Ingress networking
- Rolling updates and rollbacks
- Namespace isolation
- Resource orchestration with shell scripts

## License

This is a demonstration project for educational purposes.

## Author

Donghan5
