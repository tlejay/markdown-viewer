APP_NAME := Markdown Viewer — madebytle.com
APP := dist/$(APP_NAME).app

.PHONY: build install run clean dev

## Build the .app bundle (compile + icon + sign)
build:
	./scripts/build.sh

## Build, then install to ~/Applications and register with Launch Services
install: build
	./scripts/install.sh

## Build and open the app
run: build
	open "$(APP)"

## Fast iteration during development (debug build, run binary directly)
dev:
	swift run

## Remove build artifacts
clean:
	rm -rf .build dist Resources/AppIcon.icns
