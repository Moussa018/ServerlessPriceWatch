COMPOSE = docker-compose
PAYLOAD ?= '{"url": "https://www.amazon.fr/dp/B0CHX5T4S8", "product_id": "iphone-15"}'

.PHONY: all install-layer up deploy invoke destroy clean logs

all: install-layer up deploy

install-layer:
	@echo ">>> Installation des dépendances Python dans lambda_layers/python/ ..."
	$(COMPOSE) run --rm pip-installer
	@echo ">>> Dépendances installées."

up:
	@echo ">>> Démarrage de LocalStack ..."
	$(COMPOSE) up -d localstack
	@echo ">>> Attente de LocalStack ..."
	@until $(COMPOSE) exec localstack curl -sf http://localhost:4566/_localstack/health > /dev/null 2>&1; do \
		echo "  ... en attente ..."; sleep 3; \
	done
	@echo ">>> LocalStack est prêt."

deploy: tf-init tf-apply

tf-init:
	$(COMPOSE) run --rm terraform init

tf-apply:
	$(COMPOSE) run --rm terraform apply -auto-approve

invoke:
	$(COMPOSE) run --rm awscli lambda invoke \
		--function-name PriceScraper \
		--payload $(PAYLOAD) \
		--cli-binary-format raw-in-base64-out \
		output.json
	@cat output.json

destroy:
	$(COMPOSE) run --rm terraform destroy -auto-approve

clean:
	$(COMPOSE) down -v
	rm -f terraform/scraper.zip terraform/python_libs.zip
	rm -rf lambda_layers/python/

logs:
	$(COMPOSE) logs -f localstack
