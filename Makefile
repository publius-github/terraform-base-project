.PHONY: plan apply destroy format
.ONESHELL: # Applies to every targets in the file!

SHELL := /bin/bash

plan:
	@echo "[INFO] --> terraform plan ./terraform/${module}/${env}" && \
	./files/scripts/terraform.sh ${module} ${env} plan

apply:	
	@echo "[INFO] --> terraform apply ./terraform/${module}/${env}" && \
	./files/scripts/terraform.sh ${module} ${env} apply

destroy:	
	@echo "[INFO] --> terraform destroy ./terraform/${module}/${env}" && \
	./files/scripts/terraform.sh ${module} ${env} destroy

format:
	./files/scripts/tf-format.sh
