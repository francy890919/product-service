DOCKER_USER = francyhsu123
IMAGE_NAME = product-service
IMAGE_TAG = v1.0.0
NAMESPACE_DEV = devops-dev
NAMESPACE_STAGING = devops-staging
NAMESPACE_PROD = devops-prod

.PHONY: install lint test build push deploy deploy-staging deploy-prod clean all

install:
	pip install -r requirements.txt --break-system-packages
	pip install flake8 bandit pip-audit pytest httpx --break-system-packages

lint:
	flake8 src/ --max-line-length=120 || true

test:
	python3 -m pytest tests/ -v

security-scan:
	bandit -r src/ -f txt -o bandit-report.txt || true
	pip-audit -r requirements.txt || true

build:
	docker build -t $(DOCKER_USER)/$(IMAGE_NAME):$(IMAGE_TAG) .
	docker tag $(DOCKER_USER)/$(IMAGE_NAME):$(IMAGE_TAG) $(DOCKER_USER)/$(IMAGE_NAME):latest

push:
	docker push $(DOCKER_USER)/$(IMAGE_NAME):$(IMAGE_TAG)
	docker push $(DOCKER_USER)/$(IMAGE_NAME):latest

deploy:
	kubectl set image deployment/$(IMAGE_NAME) \
		$(IMAGE_NAME)=$(DOCKER_USER)/$(IMAGE_NAME):latest \
		-n $(NAMESPACE_DEV)

deploy-staging:
	kubectl set image deployment/$(IMAGE_NAME) \
		$(IMAGE_NAME)=$(DOCKER_USER)/$(IMAGE_NAME):latest \
		-n $(NAMESPACE_STAGING)

deploy-prod:
	kubectl set image deployment/$(IMAGE_NAME) \
		$(IMAGE_NAME)=$(DOCKER_USER)/$(IMAGE_NAME):latest \
		-n $(NAMESPACE_PROD)

clean:
	docker rmi $(DOCKER_USER)/$(IMAGE_NAME):$(IMAGE_TAG) || true
	docker rmi $(DOCKER_USER)/$(IMAGE_NAME):latest || true
	find . -type d -name __pycache__ -exec rm -rf {} + || true
	find . -name "*.pyc" -delete || true

all: install lint test security-scan build push deploy
