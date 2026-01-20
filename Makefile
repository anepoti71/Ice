APP_NAME := Ice
CONFIG ?= debug
BUILD_DIR := .build
APP_DIR := build
APP_PATH := $(APP_DIR)/$(APP_NAME).app
EXECUTABLE_PATH := $(BUILD_DIR)/$(CONFIG)/$(APP_NAME)
RESOURCE_BUNDLE := $(BUILD_DIR)/$(CONFIG)/Ice_Ice.bundle
RESOURCE_ASSET_CAR := $(RESOURCE_BUNDLE)/Contents/Resources/Assets.car
ICE_BUNDLE_RESOURCES := $(APP_PATH)/Contents/Resources/Ice_Ice.bundle/Contents/Resources
SWIFTPM_DIR := .swiftpm
SWIFTPM_CACHE := $(SWIFTPM_DIR)/cache
SWIFTPM_CONFIG := $(SWIFTPM_DIR)/configuration
SWIFTPM_SECURITY := $(SWIFTPM_DIR)/security
CLANG_MODULE_CACHE := $(SWIFTPM_DIR)/clang-module-cache

SWIFT := $(shell xcrun -f swift 2>/dev/null)
CODESIGN := $(shell xcrun -f codesign 2>/dev/null)
OPEN := $(shell xcrun -f open 2>/dev/null)
INSTALL_NAME_TOOL := $(shell xcrun -f install_name_tool 2>/dev/null)
SWIFT_ENV := SWIFTPM_CACHE_PATH="$(SWIFTPM_CACHE)" SWIFTPM_CONFIG_PATH="$(SWIFTPM_CONFIG)" SWIFTPM_SECURITY_PATH="$(SWIFTPM_SECURITY)" CLANG_MODULE_CACHE_PATH="$(CLANG_MODULE_CACHE)"

.PHONY: all build bundle run sign clean deps verify-tools install

all: build

verify-tools:
	@test -n "$(SWIFT)" || (echo "swift not found. Install Xcode Command Line Tools." && exit 1)

deps: verify-tools
	mkdir -p "$(SWIFTPM_CACHE)" "$(SWIFTPM_CONFIG)" "$(SWIFTPM_SECURITY)" "$(CLANG_MODULE_CACHE)"
	$(SWIFT_ENV) "$(SWIFT)" package resolve

build: deps
	$(SWIFT_ENV) "$(SWIFT)" build -c "$(CONFIG)"

bundle: build
	rm -rf "$(APP_PATH)"
	mkdir -p "$(APP_PATH)/Contents/MacOS" "$(APP_PATH)/Contents/Resources" "$(APP_PATH)/Contents/Frameworks"
	cp "$(EXECUTABLE_PATH)" "$(APP_PATH)/Contents/MacOS/$(APP_NAME)"
	cp "Packaging/Info.plist" "$(APP_PATH)/Contents/Info.plist"
	cp -R "Ice/Resources/." "$(APP_PATH)/Contents/Resources/"
	find "Ice/Assets.xcassets" -type f -name "*.png" -exec cp {} "$(APP_PATH)/Contents/Resources/" \;
	@if [ -d "$(RESOURCE_BUNDLE)" ]; then cp -R "$(RESOURCE_BUNDLE)" "$(APP_PATH)/Contents/Resources/"; fi
	@mkdir -p "$(ICE_BUNDLE_RESOURCES)"
	@find "Ice/Assets.xcassets" -type f -name "*.png" -exec cp {} "$(ICE_BUNDLE_RESOURCES)/" \;
	@if [ -f "$(RESOURCE_ASSET_CAR)" ]; then cp "$(RESOURCE_ASSET_CAR)" "$(APP_PATH)/Contents/Resources/"; fi
	@SPARKLE_FRAMEWORK=$$( \
		if [ -d "$(BUILD_DIR)/$(CONFIG)/Sparkle.framework" ]; then \
			echo "$(BUILD_DIR)/$(CONFIG)/Sparkle.framework"; \
		elif [ -d "$(BUILD_DIR)/arm64-apple-macosx/$(CONFIG)/Sparkle.framework" ]; then \
			echo "$(BUILD_DIR)/arm64-apple-macosx/$(CONFIG)/Sparkle.framework"; \
		else \
			find "$(BUILD_DIR)" -type d -name "Sparkle.framework" 2>/dev/null | head -n 1; \
		fi \
	); \
	if [ -n "$$SPARKLE_FRAMEWORK" ]; then \
		cp -R "$$SPARKLE_FRAMEWORK" "$(APP_PATH)/Contents/Frameworks/"; \
	else \
		echo "Sparkle.framework not found in build output"; \
	fi
	@if [ -n "$(INSTALL_NAME_TOOL)" ]; then "$(INSTALL_NAME_TOOL)" -add_rpath "@executable_path/../Frameworks" "$(APP_PATH)/Contents/MacOS/$(APP_NAME)" || true; fi

sign: bundle
	@test -n "$(CODESIGN)" || (echo "codesign not found." && exit 1)
	"$(CODESIGN)" --force --deep --sign - "$(APP_PATH)"

run: sign
	"$(OPEN)" "$(APP_PATH)"

install: sign
	cp -R "$(APP_PATH)" "/Applications/$(APP_NAME) Dev.app"

clean:
	rm -rf "$(BUILD_DIR)" "$(APP_PATH)"
