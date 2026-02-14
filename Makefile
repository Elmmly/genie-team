# Genie Team — Lint & Test
# Single source of truth for CI, pre-commit, and manual runs.

SHELL := /bin/bash
.DEFAULT_GOAL := help

# ── Configuration ────────────────────────────────────────────
SHELLCHECK_EXCLUDES := SC1091,SC2034,SC2155,SC2015,SC2317,SC1090,SC2329,SC2218
SHELLCHECK_DIRS     := commands scripts .claude/hooks
SHELLCHECK_FILES    := install.sh
DOCS_DIR            := docs
DOCS_EXCLUDE        := docs/archive

# ── Derived file lists ───────────────────────────────────────
SHELL_SOURCES = $(shell find $(SHELLCHECK_DIRS) -name '*.sh' 2>/dev/null) $(SHELLCHECK_FILES)
DOC_SOURCES   = $(shell find $(DOCS_DIR) -name '*.md' -not -path '$(DOCS_EXCLUDE)/*')
TEST_FILES    = $(shell find tests -name 'test_*.sh' | sort)

# ── Targets ──────────────────────────────────────────────────
.PHONY: help lint test ci check shellcheck lint-docs

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*##"}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

ci: lint test ## Run full CI pipeline (lint + test)

check: ci ## Alias for ci

lint: shellcheck lint-docs ## Run all linters

shellcheck: ## Lint shell scripts
	shellcheck -e $(SHELLCHECK_EXCLUDES) $(SHELL_SOURCES)

lint-docs: ## Validate doc frontmatter and cross-references
	@scripts/validate/lint-frontmatter-yaml.sh $(DOC_SOURCES)
	@scripts/validate/validate-frontmatter.sh $(DOC_SOURCES)
	@scripts/validate/check-crossrefs.sh $(DOC_SOURCES)

test: ## Run all tests
	@failed=0; \
	for f in $(TEST_FILES); do \
		echo "=== Running $$f ==="; \
		bash "$$f" || failed=1; \
	done; \
	exit $$failed
