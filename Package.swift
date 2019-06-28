// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Xcoder",
	platforms: [
		.macOS(.v10_14)
	],
	products: [
		.executable(
			name: "xcoder",
			targets: ["xcoder"]),
		.library(
			name: "XcoderKit",
			targets: ["XcoderKit"]),
		],
    dependencies: [
        .package(url: "https://github.com/g-Off/XcodeProject.git", from: "0.5.0-alpha.4"),
		.package(url: "https://github.com/g-Off/CommandRegistry.git", from: "0.1.0")
    ],
	targets: [
		.target(
			name: "xcoder",
			dependencies: [
				"XcoderKit"
			]
		),
		.target(
			name: "XcoderKit",
			dependencies: [
				"XcodeProject",
				"CommandRegistry"
			]
		)
	]
)
