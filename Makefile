.PHONY: help
help:							## Show the help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
.DEFAULT_GOAL := help

.PHONY: down
down: ## CReated setup Ansible 
	docker rm -f minecraft

.PHONY: setup
setup: ## CReated setup Ansible 
	docker rm -f minecraft
	docker build -t minecraft ./docker
	docker run -d --name minecraft -p 2222:22 minecraft

.PHONY: check
check: ## Check comunication all nodes
	ansible -i inventories/docker.yaml  -a 'date' all

.PHONY: graph
graph: ## Show graph nodes
	ansible-inventory -i inventories/docker.yaml --graph

.PHONY: exec
exec:  ## Exec playbook
	ansible-playbook  -i inventories/docker.yaml playbooks/minecraft.yaml 

.PHONY: show_ip
show_ip: ## Show ip node
	@docker inspect minecraft | jq -r '.[].NetworkSettings.Networks.bridge.IPAddress'

.PHONY: show_password
show_password: ## Show password	 node
	@docker exec -ti minecraft cat /var/lib/jenkins/secrets/initialAdminPassword

.PHONY:  sh
sh: ## Show password	 node
	docker exec -ti minecraft bash

.PHONY:  install_production
install_production: ## Install production
	ansible-playbook -i inventories/production.yaml playbook.yaml -e @production_vars.yml

