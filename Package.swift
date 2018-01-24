// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Bullwinkle",
	products: [
		.executable(
			name: "bullwinkle",
			targets: ["bullwinkle"]),
		.library(
			name: "MooseKit",
			targets: ["MooseKit"]),
		],
    dependencies: [
        .package(
			url: "https://github.com/g-Off/XcodeProject.git",
			from: "0.1.0"
		),
		.package(
			url: "https://github.com/apple/swift-package-manager.git",
			from: "0.1.0"
		)
    ],
	targets: [
		.target(
			name: "bullwinkle",
			dependencies: [
				"XcodeProject",
				"Utility",
				"MooseKit"
			]
		),
		.target(
			name: "MooseKit",
			dependencies: [
				"XcodeProject",
				"Utility"
			]
		)
	]
)
