import Foundation
import Commander
import XcodeProject

private func fileURLValidator(_ string: String) throws -> String {
	let currentDirectory: URL
	let url: URL
	currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
	url = URL(fileURLWithPath: string, relativeTo: currentDirectory)
	guard FileManager.default.fileExists(atPath: url.path) else {
		throw NSError(domain: NSURLErrorDomain, code: NSURLErrorFileDoesNotExist, userInfo: nil)
	}
	guard FileManager.default.isReadableFile(atPath: url.path) else {
		throw NSError(domain: NSURLErrorDomain, code: NSURLErrorNoPermissionsToReadFile, userInfo: nil)
	}
	return url.path
}

extension PBXGroup {
	func childGroup(path: [String]) -> PBXGroup? {
		guard !path.isEmpty else {
			return self
		}
		var path = path
		let pathName = path.removeFirst()
		let child = children.flatMap { $0 as? PBXGroup }.first {
			return $0.displayName == pathName
		}
		return child?.childGroup(path: path)
	}
}

extension PBXProject {
	func group(for path: String) -> PBXGroup? {
		let components = path.components(separatedBy: "/")
		return mainGroup.childGroup(path: components)
	}
}

extension PBXGroup.SortOption: ArgumentConvertible {
	public init(parser: ArgumentParser) throws {
		if let value = parser.shift() {
			guard let sortOption = PBXGroup.SortOption(rawValue: value) else {
				throw ArgumentError.invalidType(value: value, type: "sort option", argument: nil)
			}
			self.init(rawValue: sortOption.rawValue)!
		} else {
			throw ArgumentError.missingValue(argument: nil)
		}
	}

	public var description: String {
		return rawValue
	}
}

enum BullwinkleError: Error, CustomStringConvertible {
	case invalidProject(path: String)
	case invalidGroup(String)
	case invalidTarget(String)
	
	var description: String {
		switch self {
		case .invalidProject(let path):
			return "Invalid project at \(path)"
		case .invalidGroup(let groupPath):
			return "Invalid group path \(groupPath)"
		case .invalidTarget(let targetName):
			return "Invalid target \(targetName)"
		}
	}
}
func loadProject(projectPath: String, groupPath: String) throws -> (ProjectFile, PBXGroup) {
	guard let projectFile = try ProjectFile(url: URL(fileURLWithPath: projectPath)) else {
		throw BullwinkleError.invalidProject(path: projectPath)
	}
	let group: PBXGroup
	if groupPath.isEmpty {
		group = projectFile.project.mainGroup
	} else {
		guard let childGroup = projectFile.project.group(for: groupPath) else {
			throw BullwinkleError.invalidGroup(groupPath)
		}
		group = childGroup
	}
	return (projectFile, group)
}

private let sort = command(
	Argument<String>("xcodeproj", description: "Xcode Project file", validator: fileURLValidator),
	Option("group", default: "", description: "Group to sort"),
	Option<PBXGroup.SortOption>("order", default: .name, description: "Sort the group by one of [name, type]"),
	Flag("recursive", default: false, flag: "r", description: "Recursively descend")
) { (projectPath, groupPath, sortOrder, recursive) in
	let (projectFile, group) = try loadProject(projectPath: projectPath, groupPath: groupPath)
	group.sort(recursive: recursive, by: sortOrder)
	try projectFile.save()
}

private let sync = command(
	Argument<String>("xcodeproj", description: "Xcode Project file", validator: fileURLValidator),
	Option("group", default: "", description: "Group to sync"),
	Option("target", default: "", description: "Target to add new files"),
	Flag("recursive", default: false, flag: "r", description: "Recursively descend")
) { (projectPath, groupPath, targetName, recursive) in
	let (projectFile, group) = try loadProject(projectPath: projectPath, groupPath: groupPath)
	var target: PBXTarget? = nil
	if !targetName.isEmpty {
		target = projectFile.project.target(named: targetName)
		guard target != nil else {
			throw BullwinkleError.invalidTarget(targetName)
		}
	}
	group.sync(recursive: recursive, target: target)
	try projectFile.save()
}
let mainGroup = Group {
	$0.addCommand("sort", "Sort the Xcode project group.", sort)
	$0.addCommand("sync", "Sync the Xcode project groups with the filesystem.", sync)
}
mainGroup.run("0.1")
