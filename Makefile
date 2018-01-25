SWIFTC_FLAGS = -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"
CONFIGURATION = release

all: build

debug: CONFIGURATION = debug
debug: build

build:
	swift build --configuration $(CONFIGURATION) $(SWIFTC_FLAGS)
	
release: CONFIGURATION = release
release:
	swift build --configuration $(CONFIGURATION) $(SWIFTC_FLAGS)
	
test:
	swift test $(SWIFTC_FLAGS)
	
xcode:
	swift package generate-xcodeproj --xcconfig-overrides=overrides.xcconfig

clean:
	swift package clean