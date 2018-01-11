// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "bullwinkle",
    dependencies: [
        .package(
			url: "https://github.com/g-Off/XcodeProject.git",
			.branch("master")
		),
		.package(
			url: "https://github.com/kylef/Commander.git",
			from: "0.8.0"
		)
    ],
    targets: [
        .target(
            name: "bullwinkle",
            dependencies: ["XcodeProject", "Commander"]),
    ]
)
