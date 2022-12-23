.PHONY: run
run: ## Run playbook to setup Kubernetes cluster
	@ansible-playbook main.yaml --extra-vars="wsl_username=$$(whoami)" --ask-become-pass

.PHONY: run-user
run-user: ## Run playbook to setup Kubernetes cluster
	@ansible-playbook user.yaml

.PHONY: inventory-graph
inventory-graph: ## Display the inventory as seen from Ansible
	@ansible-inventory --graph $(opts)

.PHONY: inventory-list
inventory-list: ## Display the inventory as seen from Ansible
	@ansible-inventory --list $(opts)

.PHONY: lint
lint: ## Check syntax of the playbook
	@ansible-playbook --syntax-check $(opts) "main.yaml"

.PHONY: ping
ping: ## Ping all nodes in the cluster to ensure SSH connections are working
	@ansible all -m ping

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
