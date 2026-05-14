.PHONY: run run-web run-emulator build-debug build-release install deploy clean analyze test

# Optional: override Supabase config via env vars
# e.g.  make run SUPABASE_URL=https://… SUPABASE_ANON_KEY=…
DART_DEFINES =
ifdef SUPABASE_URL
DART_DEFINES += --dart-define=SUPABASE_URL=$(SUPABASE_URL)
endif
ifdef SUPABASE_ANON_KEY
DART_DEFINES += --dart-define=SUPABASE_ANON_KEY=$(SUPABASE_ANON_KEY)
endif

# Deploy debug build to connected Android device
run:
	flutter run $(DART_DEFINES) -d $(shell flutter devices | grep android | head -1 | sed 's/.*• \([^ ]*\) •.*/\1/')

# Run on local Android emulator
run-emulator:
	flutter run $(DART_DEFINES) -d emulator

# Run on Chrome for local web testing
run-web:
	flutter run $(DART_DEFINES) -d chrome

# Build debug APK
build-debug:
	flutter build apk --debug $(DART_DEFINES)

# Build release APK
build-release:
	flutter build apk --release $(DART_DEFINES)

# Install debug APK to connected device via ADB
install:
	flutter install -d $(shell flutter devices | grep android | head -1 | sed 's/.*• \([^ ]*\) •.*/\1/')

# Build release APK and install to emulator
deploy: build-release
	adb install -r build/app/outputs/flutter-apk/app-release.apk

# Run static analysis
analyze:
	flutter analyze --no-fatal-infos --no-fatal-warnings

# Run tests
test:
	flutter test

# Clean build artifacts
clean:
	flutter clean && flutter pub get
