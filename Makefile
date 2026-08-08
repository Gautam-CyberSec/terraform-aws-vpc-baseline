.DEFAULT_GOAL := check
.PHONY: check fmt validate lint docs docs-check clean

MODULES := modules/network modules/iam
DIRS    := . examples/minimal examples/complete

## check: everything CI runs
check: fmt validate lint docs-check

## fmt: rewrite files to canonical style
fmt:
	terraform fmt -recursive

## validate: type and reference checks, no AWS credentials needed
validate:
	@for d in $(DIRS); do \
		echo "→ $$d"; \
		terraform -chdir=$$d init -backend=false -input=false >/dev/null; \
		terraform -chdir=$$d validate; \
	done

## lint: tflint with the AWS ruleset
lint:
	@tflint --init >/dev/null
	tflint --recursive --format compact

## docs: regenerate the input/output tables in each module README
docs:
	@for m in $(MODULES); do \
		terraform-docs -c .terraform-docs.yml $$m >/dev/null && echo "→ $$m/README.md"; \
	done

## docs-check: fail if the committed tables are stale
docs-check: docs
	@git diff --exit-code --name-only $(MODULES) \
		|| (echo "\nModule docs are out of date. Run 'make docs' and commit the result." && exit 1)
	@echo "docs up to date"

## clean: remove local Terraform working directories
clean:
	find . -type d -name .terraform -prune -exec rm -rf {} +
