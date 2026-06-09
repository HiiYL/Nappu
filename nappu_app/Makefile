.PHONY: run run-web run-emulator build-debug build-release install install-emulator build-install-emulator launch-emulator deploy clean analyze test

# Optional: override Supabase config via env vars
# e.g.  make run SUPABASE_URL=https://… SUPABASE_ANON_KEY=…
EMULATOR ?= emulator-5554
APP_ID ?= com.nappu.app
FLUTTER ?= $(shell command -v flutter 2>/dev/null || printf '%s' "$$HOME/development/flutter/bin/flutter")
ADB ?= $(shell command -v adb 2>/dev/null || printf '%s' "$$HOME/Library/Android/sdk/platform-tools/adb")
DART_DEFINES =
ifdef SUPABASE_URL
DART_DEFINES += --dart-define=SUPABASE_URL=$(SUPABASE_URL)
endif
ifdef SUPABASE_ANON_KEY
DART_DEFINES += --dart-define=SUPABASE_ANON_KEY=$(SUPABASE_ANON_KEY)
endif

# Deploy debug build to connected Android device
run:
	$(FLUTTER) run $(DART_DEFINES) -d $(shell $(FLUTTER) devices | grep android | head -1 | sed 's/.*• \([^ ]*\) •.*/\1/')

# Run on local Android emulator
run-emulator:
	$(FLUTTER) run $(DART_DEFINES) -d emulator

# Run on Chrome for local web testing
run-web:
	$(FLUTTER) run $(DART_DEFINES) -d chrome

# Build debug APK
build-debug:
	$(FLUTTER) build apk --debug $(DART_DEFINES)

# Build release APK
build-release:
	$(FLUTTER) build apk --release $(DART_DEFINES)

# Install debug APK to connected device via ADB
install:
	$(FLUTTER) install -d $(shell $(FLUTTER) devices | grep android | head -1 | sed 's/.*• \([^ ]*\) •.*/\1/')

# Install the already-built debug APK to a running emulator
install-emulator:
	$(ADB) -s $(EMULATOR) install -r build/app/outputs/flutter-apk/app-debug.apk

# Build the debug APK, install it to a running emulator, then launch it
build-install-emulator: build-debug install-emulator launch-emulator

# Launch the installed app on a running emulator
launch-emulator:
	$(ADB) -s $(EMULATOR) shell monkey -p $(APP_ID) -c android.intent.category.LAUNCHER 1

# Build release APK and install to emulator
deploy: build-release
	$(ADB) install -r build/app/outputs/flutter-apk/app-release.apk

# Run static analysis
analyze:
	$(FLUTTER) analyze --no-fatal-infos --no-fatal-warnings

# Run tests
test:
	$(FLUTTER) test

# Clean build artifacts
clean:
	$(FLUTTER) clean && $(FLUTTER) pub get
