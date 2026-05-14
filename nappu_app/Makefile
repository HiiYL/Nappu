.PHONY: run run-web build-debug build-release build-web install clean analyze test

# Deploy debug build to connected Android device
run:
	flutter run -d $(shell flutter devices | grep android | head -1 | sed 's/.*• \([^ ]*\) •.*/\1/')

# Run on Chrome for local web testing
run-web:
	flutter run -d chrome

# Build debug APK
build-debug:
	flutter build apk --debug

# Build release APK
build-release:
	flutter build apk --release

# Install debug APK to connected device via ADB
install:
	flutter install -d $(shell flutter devices | grep android | head -1 | sed 's/.*• \([^ ]*\) •.*/\1/')

# Run static analysis
analyze:
	flutter analyze --no-fatal-infos --no-fatal-warnings

# Run tests
test:
	flutter test

# Clean build artifacts
clean:
	flutter clean && flutter pub get
