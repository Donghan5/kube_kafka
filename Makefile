################
# Define Colors#
################
GREEN=\033[0;32m
YELLOW=\033[0;33m
RED=\033[0;31m
NC=\033[0m

all: deploy

deploy:
	@printf "${GREEN}Starting deployment of Kafka environment...${NC}\n"
	./deploy_all.sh

clean:
	@printf "${YELLOW}Cleaning up Kafka environment...${NC}\n"
	kubectl delete namespace kafka

fclean: clean
	@printf "${YELLOW}Deleting Minikube cluster...${NC}\n"
	minikube delete

rollout-check:
	@printf "${YELLOW}Checking rollout status for webapp (Deployment)...${NC}\n"
	@kubectl rollout status deployment/webapp -n kafka || true
	
	@printf "${YELLOW}Checking rollout status for postgres-db (StatefulSet)...${NC}\n"
	@kubectl rollout status statefulset/postgres-db -n kafka || true
	
	@printf "${RED}[Expected output] error: 'deployment \"webapp\" exceeded its progress deadline' if rollout failed.${NC}\n"
	
	@printf "${YELLOW}Watching Pod changes in real-time (Press Ctrl+C to stop)...${NC}\n"
	kubectl get pods -n kafka -w

rollback:
	@printf "${YELLOW}Checking rollout history for webapp deployment...${NC}\n"
	kubectl rollout history deployment/webapp -n kafka
	@printf "${YELLOW}Rolling back to previous revision for webapp deployment...${NC}\n"
	kubectl rollout undo deployment/webapp -n kafka

.PHONY: all deploy clean fclean rollout-check rollback