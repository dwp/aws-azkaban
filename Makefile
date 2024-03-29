SHELL:=bash

aws_profile=default
aws_region=eu-west-2

default: help

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: bootstrap
bootstrap: ## Bootstrap local environment for first use
	@make git-hooks
	pip3 install --user Jinja2 PyYAML boto3
	@{ \
		export AWS_PROFILE=$(aws_profile); \
		export AWS_REGION=$(aws_region); \
		python3 bootstrap_terraform.py; \
	}
	terraform fmt -recursive
	terraform init
	make get-dependencies

.PHONY: git-hooks
git-hooks: ## Set up hooks in .githooks
	@git submodule update --init .githooks ; \
	git config core.hooksPath .githooks \


.PHONY: terraform-init
terraform-init: ## Run `terraform init` from repo root
	terraform init

.PHONY: terraform-plan
terraform-plan: ## Run `terraform plan` from repo root
	terraform plan

.PHONY: terraform-apply
terraform-apply: ## Run `terraform apply` from repo root
	terraform apply

.PHONY: terraform-workspace-new
terraform-workspace-new: ## Creates new Terraform workspace with Concourse remote execution. Run `terraform-workspace-new workspace=<workspace_name>`
	fly -t aws-concourse execute --config create-workspace.yml --input repo=. -v workspace="$(workspace)"

.PHONY: get-dependencies
get-dependencies: ## Get dependencies that are normally managed by pipeline
	@{ \
		for github_repository in manage-mysql-user; do \
			export REPO=$${github_repository}; \
			./get_lambda_release.sh; \
		done \
	}

concourse-login:
	fly --target aws-concourse set-pipeline --pipeline aws-azkaban --config aviator_pipeline.yml

.PHONY: unittest
unittest:
	tox

.PHONY: artefact
artefact:
	rm -rf artefact build
	mkdir artefact build
	pip install -r requirements.txt -t artefact
	cp azkaban_zip_uploader/*.py artefact/
	cd artefact && zip -r ../build/azkaban_zip_uploader.zip ./ && cd -

clean:
	rm -rf artefact build
