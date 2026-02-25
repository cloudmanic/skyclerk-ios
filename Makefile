#
# Makefile
#
# Created on 2026-02-25.
# Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
#

PROJECT = Skyclerk.xcodeproj
SCHEME = Skyclerk
CONFIGURATION = Debug
BUILD_DIR = build

# Find a simulator matching the SDK. Use iPhone 17 Pro for iOS 26.x, fallback to iPhone 16.
SIMULATOR_ID := $(shell xcrun simctl list devices available | grep -A 100 "iOS 26" | grep iPhone | head -1 | grep -oE '[0-9A-F-]{36}' || xcrun simctl list devices available | grep iPhone | head -1 | grep -oE '[0-9A-F-]{36}')
SIMULATOR_NAME := $(shell xcrun simctl list devices available | grep -A 100 "iOS 26" | grep iPhone | head -1 | xargs | cut -d' ' -f1-4)

.PHONY: help generate build run clean open typecheck lint stop wipe

## —— Help ——————————————————————————————————————
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

info: ## Show detected build environment
	@echo "Simulator:  $(SIMULATOR_NAME)"
	@echo "Sim ID:     $(SIMULATOR_ID)"
	@echo "Runtime:    iOS $(SIM_OS)"
	@echo "SDK:        $$(xcodebuild -showsdks 2>/dev/null | grep 'iOS Sim' | awk '{print $$NF}')"

## —— Project Generation ————————————————————————
generate: ## Regenerate Xcode project from project.yml
	xcodegen generate

## —— Build ——————————————————————————————————————
build: generate ## Build the app for simulator
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination 'platform=iOS Simulator,id=$(SIMULATOR_ID)' \
		-configuration $(CONFIGURATION) \
		EXCLUDED_ARCHS= \
		build \
		2>&1 | tail -20

build-quiet: generate ## Build the app (minimal output)
	@xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination 'platform=iOS Simulator,id=$(SIMULATOR_ID)' \
		-configuration $(CONFIGURATION) \
		EXCLUDED_ARCHS= \
		build \
		2>&1 | grep -E "error:|warning:|BUILD|Compiling" | head -30; \
	RESULT=$$?; \
	if [ $$RESULT -eq 0 ]; then \
		echo "\033[32m✓ Build succeeded\033[0m"; \
	fi

build-release: generate ## Build the app in Release mode
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination 'platform=iOS Simulator,id=$(SIMULATOR_ID)' \
		-configuration Release \
		EXCLUDED_ARCHS= \
		build

## —— Run ————————————————————————————————————————
run: build ## Build and run on simulator
	@xcrun simctl boot $(SIMULATOR_ID) 2>/dev/null || true
	@open -a Simulator
	@sleep 2
	@APP_PATH=$$(find ~/Library/Developer/Xcode/DerivedData/Skyclerk-*/Build/Products/$(CONFIGURATION)-iphonesimulator -name "Skyclerk.app" -maxdepth 1 2>/dev/null | head -1); \
	if [ -n "$$APP_PATH" ]; then \
		xcrun simctl install $(SIMULATOR_ID) "$$APP_PATH"; \
		xcrun simctl launch $(SIMULATOR_ID) com.cloudmanic.skyclerk; \
		echo "\033[32m✓ Skyclerk launched on $(SIMULATOR_NAME)\033[0m"; \
	else \
		echo "\033[31m✗ Could not find Skyclerk.app in DerivedData\033[0m"; \
		exit 1; \
	fi

install: ## Install last build to simulator (no rebuild)
	@xcrun simctl boot $(SIMULATOR_ID) 2>/dev/null || true
	@open -a Simulator
	@sleep 2
	@APP_PATH=$$(find ~/Library/Developer/Xcode/DerivedData/Skyclerk-*/Build/Products/$(CONFIGURATION)-iphonesimulator -name "Skyclerk.app" -maxdepth 1 2>/dev/null | head -1); \
	if [ -n "$$APP_PATH" ]; then \
		xcrun simctl install $(SIMULATOR_ID) "$$APP_PATH"; \
		xcrun simctl launch $(SIMULATOR_ID) com.cloudmanic.skyclerk; \
		echo "\033[32m✓ Skyclerk launched on $(SIMULATOR_NAME)\033[0m"; \
	else \
		echo "\033[31m✗ No build found. Run 'make build' first.\033[0m"; \
		exit 1; \
	fi

boot: ## Boot the simulator without building
	xcrun simctl boot $(SIMULATOR_ID) 2>/dev/null || true
	open -a Simulator

stop: ## Shutdown the simulator
	xcrun simctl shutdown $(SIMULATOR_ID) 2>/dev/null || true

## —— Validation —————————————————————————————————
typecheck: ## Type-check all Swift code (fast, no full build)
	@SDK_PATH=$$(xcrun --sdk iphonesimulator --show-sdk-path) && \
	find Skyclerk -name "*.swift" | sort | xargs \
		swiftc -typecheck \
		-sdk "$$SDK_PATH" \
		-target arm64-apple-ios18.0-simulator && \
	echo "\033[32m✓ All Swift files type-check clean\033[0m"

lint: ## Show any Swift compiler warnings
	@SDK_PATH=$$(xcrun --sdk iphonesimulator --show-sdk-path) && \
	find Skyclerk -name "*.swift" | sort | xargs \
		swiftc -typecheck \
		-sdk "$$SDK_PATH" \
		-target arm64-apple-ios18.0-simulator \
		-warnings-as-errors 2>&1 || true

## —— Utilities ——————————————————————————————————
open: ## Open project in Xcode
	open $(PROJECT)

clean: ## Clean build artifacts
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean 2>/dev/null || true
	rm -rf $(BUILD_DIR)
	rm -rf ~/Library/Developer/Xcode/DerivedData/Skyclerk-*
	@echo "\033[32m✓ Clean complete\033[0m"

wipe: clean ## Clean everything and regenerate
	rm -rf $(PROJECT)
	$(MAKE) generate

count: ## Count lines of Swift code
	@find Skyclerk -name "*.swift" | sort | xargs wc -l

files: ## List all Swift source files
	@find Skyclerk -name "*.swift" | sort

simulators: ## List available iPhone simulators
	@xcrun simctl list devices available | grep "iPhone"

runtimes: ## List installed simulator runtimes
	@xcrun simctl runtime list

logs: ## Stream API logs from the simulator in real time
	xcrun simctl spawn booted log stream --predicate 'subsystem == "com.cloudmanic.skyclerk"' --style compact

download-runtime: ## Download the iOS simulator runtime matching your SDK
	xcodebuild -downloadPlatform iOS
