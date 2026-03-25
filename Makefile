# Makefile for the Terraform AWS WordPress platform project.
# Use these targets as the standard human-friendly entrypoints for common lifecycle commands.

TF              := terraform
PLAN_FILE       := tfplan
AWS_PROFILE     ?= terraform-exam
AWS_REGION      ?= eu-west-3

.PHONY: help fmt init validate plan plan-save plan-summary plan-counts apply destroy output show clean aws-whoami aws-azs

help:
	@echo "Available targets:"
	@echo "  make fmt           - Format all Terraform files recursively"
	@echo "  make init          - Initialize Terraform providers and modules"
	@echo "  make validate      - Validate the Terraform configuration"
	@echo "  make plan          - Show a normal Terraform plan"
	@echo "  make plan-save     - Save the plan to $(PLAN_FILE)"
	@echo "  make plan-summary  - Show only planned create/update/delete resource entries"
	@echo "  make plan-counts   - Show planned resource counts grouped by type"
	@echo "  make apply         - Apply the saved plan file $(PLAN_FILE)"
	@echo "  make destroy       - Destroy all managed resources"
	@echo "  make output        - Show Terraform outputs"
	@echo "  make show          - Show the saved plan file in human-readable form"
	@echo "  make clean         - Remove local Terraform plan artifacts"
	@echo "  make aws-whoami    - Show the currently active AWS identity"
	@echo "  make aws-azs       - Show available AZs in $(AWS_REGION)"

fmt:
	@# Format all Terraform files in the root module and submodules.
	$(TF) fmt -recursive

init:
	@# Initialize the working directory, providers, and modules.
	$(TF) init

validate:
	@# Check whether the configuration is syntactically and structurally valid.
	$(TF) validate

plan:
	@# Show a normal speculative plan in the terminal.
	$(TF) plan

plan-save:
	@# Save the current plan to $(PLAN_FILE) for later inspection or apply.
	$(TF) plan -out=$(PLAN_FILE)

plan-summary:
	@# Show only the planned resource actions in a compact readable list.
	$(TF) show -json $(PLAN_FILE) \
	| jq -r '.resource_changes[] | "\(.change.actions | join(",")) \(.type).\(.name)"'

plan-counts:
	@# Show a grouped count of planned resource changes by Terraform resource type.
	$(TF) show -json $(PLAN_FILE) \
	| jq -r '[.resource_changes[] | .type] | group_by(.) | map("\(length)x \(.[0])") | .[]'

apply:
	@# Apply the previously saved plan file so the exact reviewed plan gets executed.
	$(TF) apply $(PLAN_FILE)

destroy:
	@# Destroy all Terraform-managed infrastructure in the current state.
	$(TF) destroy

output:
	@# Print the current Terraform outputs after apply.
	$(TF) output

show:
	@# Show the saved plan file in normal human-readable Terraform format.
	$(TF) show $(PLAN_FILE)

clean:
	@# Remove local plan artifacts that are safe to recreate.
	rm -f $(PLAN_FILE)

aws-whoami:
	@# Show which AWS identity/profile is currently active for this shell.
	AWS_PROFILE=$(AWS_PROFILE) aws sts get-caller-identity

aws-azs:
	@# Show the available Availability Zones in the selected AWS region.
	AWS_PROFILE=$(AWS_PROFILE) aws ec2 describe-availability-zones --region $(AWS_REGION) --query 'AvailabilityZones[].ZoneName' --output table

plan-json:
	@# Export the saved Terraform plan as JSON for jq-based inspection and Rover.
	terraform show -json $(PLAN_FILE) > plan.json

graph-plan-svg:
	@# Generate a Terraform dependency graph from the current plan as SVG.
	terraform graph -type=plan | dot -Tsvg > terraform-plan-graph.svg

graph-plan-png:
	@# Generate a Terraform dependency graph from the current plan as PNG.
	terraform graph -type=plan | dot -Tpng > terraform-plan-graph.png

rover-plan:
	@# Start Rover locally in Docker using the generated plan.json file.
	docker run --rm -it -p 9000:9000 \
		-v $(PWD)/plan.json:/src/plan.json \
		im2nguyen/rover:latest \
		-planJSONPath=plan.json

rover-image:
	@# Generate a static Rover SVG/image artifact instead of running the local web UI.
	docker run --rm -it -v "$(PWD):/src" im2nguyen/rover -genImage true

inframap-png:
	@# Generate a provider-focused infrastructure graph from the current Terraform HCL.
	inframap generate . | dot -Tpng > inframap.png

inframap-state-png:
	@# Generate a provider-focused infrastructure graph from the current Terraform state.
	inframap generate terraform.tfstate | dot -Tpng > inframap-state.png
		