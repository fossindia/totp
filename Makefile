.PHONY: help setup clean test test-coverage analyze build-apk build-ios format lint mocks coverage ci

# Default target
help: ## Show this help message
	@echo "TOTP Authenticator App - Development Commands"
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

setup: ## Install dependencies and generate code
	flutter pub get
	flutter pub run build_runner build --delete-conflicting-outputs

clean: ## Clean build artifacts and generated files
	flutter clean
	rm -rf coverage/
	rm -rf .dart_tool/build/
	find . -name "*.g.dart" -delete
	find . -name "*.mocks.dart" -delete

test: ## Run all tests
	flutter pub run build_runner build --delete-conflicting-outputs
	flutter test --test-randomize-ordering-seed random

test-coverage: ## Run tests with coverage reporting
	./test_coverage.sh

analyze: ## Run static analysis
	flutter analyze

build-apk: ## Build Android APK
	flutter build apk --release

build-ios: ## Build iOS app (requires macOS)
	flutter build ios --release --no-codesign

format: ## Format code
	dart format lib/ test/

lint: ## Run linting
	flutter analyze

mocks: ## Generate mock classes
	flutter pub run build_runner build --delete-conflicting-outputs

coverage: ## Generate and view coverage report
	./test_coverage.sh
	@if [ -f "coverage/html/index.html" ]; then \
		echo "Opening coverage report..."; \
		xdg-open coverage/html/index.html 2>/dev/null || open coverage/html/index.html 2>/dev/null || echo "Please open coverage/html/index.html in your browser"; \
	fi

ci: ## Run CI pipeline locally (analyze + test + coverage)
	flutter analyze
	./test_coverage.sh

# Development workflow
dev: setup mocks test ## Full development setup (setup, mocks, test)

# Quality checks
quality: format lint analyze test-coverage ## Run all quality checks

# Build all targets
build-all: build-apk build-ios ## Build for all platforms

# Clean and rebuild
rebuild: clean setup ## Clean and rebuild everything