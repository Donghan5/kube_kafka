all: deploy

deploy:
	./deploy_all.sh

clean:
	kubectl delete namespace kafka

fclean: clean
	minikube delete

rollout-check:
	@echo "Checking rollout status for webapp (Deployment)..."
	kubectl rollout status deployment/webapp -n kafka
	@echo "Checking rollout status for postgres-db (StatefulSet)..."
	kubectl rollout status statefulset/postgres-db -n kafka
	@echo "Watching Pod changes in real-time (Press Ctrl+C to stop)..."
	kubectl get pods -n kafka -w

rollback:
	@echo "Checking rollout history for webapp deployment..."
	kubectl rollout history deployment/webapp -n kafka
	@echo "Rolling back to previous revision for webapp deployment..."
	kubectl rollout undo deployment/webapp -n kafka

.PHONY: all deploy clean fclean rollout-check rollback