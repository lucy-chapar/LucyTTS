# Lucy TTS dev shortcuts. Every target auto-selects an installed Xcode so
# nothing here depends on `xcode-select -p` being correct.

.PHONY: help build test run ios-build doctor clean

help: ## Show this help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the macOS app (SwiftPM).
	@./scripts/build.sh

test: ## Run the macOS test suite.
	@./scripts/test.sh

run: ## Build and launch Lucy TTS as a real .app bundle.
	@./scripts/run.sh

ios-build: ## Build the iPhone target for the iOS Simulator (smoke test, no signing).
	@./scripts/ios-build.sh

doctor: ## Diagnose the build toolchain (Xcode location, versions).
	@./scripts/doctor.sh

clean: ## Remove SwiftPM and direct-build artifacts.
	@rm -rf .build
	@echo "Cleaned .build/"
