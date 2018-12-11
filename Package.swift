// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "Xcoder",
	products: [
		.executable(
			name: "xcoder",
			targets: ["xcoder"]),
		.library(
			name: "XcoderKit",
			targets: ["XcoderKit"]),
		],
    dependencies: [
        .package(url: "https://github.com/g-Off/XcodeProject.git", from: "0.4.0"),
		.package(url: "https://github.com/g-Off/CommandRegistry.git", .branch("master"))
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
