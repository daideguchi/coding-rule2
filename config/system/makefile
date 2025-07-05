.PHONY: help dev test lint format clean install build docs
.DEFAULT_GOAL := help

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

dev: ## Setup development environment
	pip install -e ".[dev]"
	pre-commit install

install: ## Install package
	pip install -e .

test: ## Run tests
	pytest tests/ -v

test-unit: ## Run unit tests only
	pytest tests/unit/ -v

test-integration: ## Run integration tests only
	pytest tests/integration/ -v

test-e2e: ## Run end-to-end tests only
	pytest tests/e2e/ -v

test-cov: ## Run tests with coverage
	pytest tests/ --cov=src --cov-report=html --cov-report=term

lint: ## Run linting
	ruff check src/ tests/
	mypy src/

format: ## Format code
	black src/ tests/
	ruff check src/ tests/ --fix

clean: ## Clean build artifacts
	rm -rf build/
	rm -rf dist/
	rm -rf *.egg-info/
	rm -rf .pytest_cache/
	rm -rf .coverage
	rm -rf htmlcov/
	find . -type d -name __pycache__ -delete
	find . -type f -name "*.pyc" -delete

build: ## Build package
	python -m build

docs: ## Build documentation
	mkdocs build

docs-serve: ## Serve documentation locally
	mkdocs serve

ai-agents: ## Start AI agents system
	python scripts/start_agents.py

claude-auth: ## Start Claude authentication flow
	python scripts/claude_auth.py

setup-portable: ## Setup portable system
	bash scripts/setup-portable.sh

verify-system: ## Verify system integrity
	python scripts/verify_system.py
# Task Status Management
.PHONY: status status-brief status-update tasks

status:
	@python3 scripts/auto-status-display.py --brief

status-brief:
	@cat .task_status 2>/dev/null || echo "🎯 No active tasks"

status-update:
	@python3 scripts/auto-status-display.py

tasks:
	@cat STATUS.md

# Quick development workflow
.PHONY: dev-start dev-status dev-commit

dev-start:
	@echo "🚀 Development session starting..."
	@python3 scripts/auto-status-display.py --brief
	@echo "💡 Use 'make status' for quick task check"

dev-status:
	@python3 scripts/auto-status-display.py --brief

dev-commit:
	@python3 scripts/auto-status-display.py
	@echo "📝 Ready to commit. Current status updated."
