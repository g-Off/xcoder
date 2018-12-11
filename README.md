# xcoder

A simple command line tool for sorting and syncing an Xcode project file.

* Groups can be sorted (recursively if desired) either alphabetically or by type.
* Groups can be synchronized (recursively if desired) with their on disk folder. This will add new files and folders and delete ones that are no longer present.

## Building

Use the included Makefile, otherwise you'll need to include a few build options to make the tool build using macOS 10.11+ (instead of Swift Package Managers hardcoded macOS 10.10).
