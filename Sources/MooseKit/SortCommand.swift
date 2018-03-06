//
//  SortCommand.swift
//  bullwinkle
//
//  Created by Geoffrey Foster on 2018-01-10.
//

import Foundation
import Utility
import XcodeProject
import Basic

extension PBXGroup.SortOption: StringEnumArgument {
	static var options: [(name: String, description: String)] = [
		(name: PBXGroup.SortOption.name.rawValue, description: "Sort by name"),
		(name: PBXGroup.SortOption.type.rawValue, description: "Sort by type")
	]
	public static var completion: ShellCompletion {
		return .values(options.map { (value: $0.name, description: $0.description) })
	}
}

final class SortArguments {
	enum BuildPhase: String {
		case frameworks
		case headers
		case resources
		case sources
		
		func matches(buildPhase: PBXBuildPhase) -> Bool {
			switch self {
			case .frameworks where buildPhase is PBXFrameworksBuildPhase:
				return true
			case .headers where buildPhase is PBXHeadersBuildPhase:
				return true
			case .resources where buildPhase is PBXResourcesBuildPhase:
				return true
			case .sources where buildPhase is PBXSourcesBuildPhase:
				return true
			default:
				return false
			}
		}
	}
	
	var xcodeproj: Foundation.URL?
	var order: PBXGroup.SortOption = .name
	
	var group: String?
	var recursive: Bool = false
	
	var target: String?
	var phase: BuildPhase = .sources
	var overrides: [String] = []
}

extension SortArguments.BuildPhase: StringEnumArgument {
	static var completion: ShellCompletion {
		return .values(
			[
				(value: SortArguments.BuildPhase.frameworks.rawValue, description: "Frameworks build phase"),
				(value: SortArguments.BuildPhase.headers.rawValue, description: "Headers build phase"),
				(value: SortArguments.BuildPhase.resources.rawValue, description: "Resources build phase"),
				(value: SortArguments.BuildPhase.sources.rawValue, description: "Sources build phase")
			]
		)
	}
}

final class SortCommand: Command {
	private static func projectLoaded(from arguments: SortArguments) throws -> ProjectFile {
		func projectURL(from arguments: SortArguments, currentWorkingDirectory: AbsolutePath = currentWorkingDirectory) throws -> Foundation.URL {
			if let xcodeproj = arguments.xcodeproj {
				return xcodeproj
			}
			let dirs = try localFileSystem.getDirectoryContents(currentWorkingDirectory)
			if let xcodeproj = dirs.first(where: { $0.hasPrefix("xcodeproj") }) {
				return URL(fileURLWithPath: xcodeproj, relativeTo: URL(fileURLWithPath: currentWorkingDirectory.asString, isDirectory: true))
			}
			throw Bullwinkle.Error.invalidProject(path: nil)
		}
		let xcodeproj = try projectURL(from: arguments)
		guard let projectFile = try ProjectFile(url: xcodeproj) else {
			throw Bullwinkle.Error.invalidProject(path: xcodeproj.path)
		}
		return projectFile
	}
	
	final class Group: Command {
		let name: String = "group"
		let binder: ArgumentBinder<SortArguments>
		
		required init(parser: ArgumentParser, binder: ArgumentBinder<SortArguments>) {
			self.binder = binder
			let subparser = parser.add(subparser: name, overview: "Sorts the given group (or top-level)")
			binder.bind(positional: subparser.add(positional: "group", kind: String.self, optional: true, usage: "Group name to sort. For a nested group specify the full path from parent to child with / inbetween.")) { (sortArguments, group) in
				sortArguments.group = group
			}
			binder.bind(option: subparser.add(option: "--recursive", shortName: "-r", kind: Bool.self, usage: "Recursively descend through all child groups.")) { (sortArguments, recursive) in
				sortArguments.recursive = recursive
			}
		}
		
		func execute(parsedArguments: ArgumentParser.Result) throws {
			var arguments = SortArguments()
			binder.fill(parsedArguments, into: &arguments)
			let projectFile = try SortCommand.projectLoaded(from: arguments)
			let group = try projectFile.group(forPath: arguments.group)
			group.sort(recursive: arguments.recursive, by: arguments.order)
			try projectFile.save()
		}
	}
	final class BuildPhase: Command {
		let name: String = "phase"
		let binder: ArgumentBinder<SortArguments>
		
		required init(parser: ArgumentParser, binder: ArgumentBinder<SortArguments>) {
			self.binder = binder
			let subparser = parser.add(subparser: name, overview: "Sorts the given phase (or top-level)")
			binder.bind(positional: subparser.add(positional: "phase", kind: SortArguments.BuildPhase.self, optional: true, usage: "Name of the build phase to sort.")) { (sortArguments, phase) in
				sortArguments.phase = phase
			}
			binder.bind(option: subparser.add(option: "--target", shortName: "-t", kind: String.self, usage: "Name of the target.")) { (sortArguments, target) in
				sortArguments.target = target
			}
			binder.bindArray(option: subparser.add(option: "--override-group", kind: [String].self, strategy: .upToNextOption)) { (sortArguments, overrides) in
				sortArguments.overrides = overrides
			}
		}
		
		func execute(parsedArguments: ArgumentParser.Result) throws {
			func findTarget(from projectFile: ProjectFile, named targetName: String?) throws -> PBXTarget {
				let foundTarget: PBXTarget?
				if let targetName = targetName {
					foundTarget = projectFile.project.targets.first { $0.name == targetName }
				} else {
					foundTarget = projectFile.project.targets.first
				}
				guard let target = foundTarget else {
					throw Bullwinkle.Error.invalidTarget(targetName ?? "No target specified")
				}
				return target
			}
			
			func sort(phase: PBXBuildPhase, order: PBXReference.SortOption, overrides: [PBXGroup]) {
				phase.sort(by: order)
				
				var indices: [Int] = []
				for index in phase.files.indices {
					let buildFile = phase.files[index]
					guard let fileRef = buildFile.fileRef else { continue }
					if let _ = overrides.first(where: { $0.contains(fileRef, recursive: true) }) {
						indices.append(index)
					}
				}
				
				let files = indices.map { phase.files[$0] }
				for index in indices.lazy.reversed() {
					phase.remove(at: index)
				}
				phase.insert(contentsOf: files, at: 0)
			}
			var arguments = SortArguments()
			binder.fill(parsedArguments, into: &arguments)
			let projectFile = try SortCommand.projectLoaded(from: arguments)
			
			let overrideGroups = try arguments.overrides.flatMap { try projectFile.group(forPath: $0) }
			let target = try findTarget(from: projectFile, named: arguments.target)
			if let phase = target.buildPhases.first(where: { arguments.phase.matches(buildPhase: $0) }) {
				sort(phase: phase, order: arguments.order, overrides: overrideGroups)
			} else {
				target.buildPhases.forEach { phase in
					guard SortArguments.BuildPhase.frameworks.matches(buildPhase: phase) ||
						SortArguments.BuildPhase.headers.matches(buildPhase: phase) ||
						SortArguments.BuildPhase.resources.matches(buildPhase: phase) ||
						SortArguments.BuildPhase.sources.matches(buildPhase: phase) else {
							return
					}
					sort(phase: phase, order: arguments.order, overrides: overrideGroups)
				}
			}
			try projectFile.save()
		}
	}
	let name: String = "sort"
	let binder = ArgumentBinder<SortArguments>()
	let subparser: ArgumentParser
	let commands: [Command]
	
	required init(parser: ArgumentParser) {
		subparser = parser.add(subparser: name, overview: "Sorts the given group (or top-level)")
		commands = [
			Group(parser: subparser, binder: binder),
			BuildPhase(parser: subparser, binder: binder)
		]
		binder.bind(option: subparser.add(option: "--xcodeproj", kind: PathArgument.self, usage: "Xcode Project file.")) { (sortArguments, xcodeproj) in
			sortArguments.xcodeproj = URL(fileURLWithPath: xcodeproj.path.asString)
		}
		binder.bind(option: subparser.add(option: "--order", shortName: "-o", kind: PBXGroup.SortOption.self, usage: "Sort the group by one of [\(PBXGroup.SortOption.options.map { $0.name }.joined(separator: ", "))]")) { (sortArguments, order) in
			sortArguments.order = order
		}
	}
	
	func execute(parsedArguments: ArgumentParser.Result) throws {
		if let commandName = parsedArguments.subparser(subparser),
			let command = commands.first(where: { $0.name == commandName }) {
			try command.execute(parsedArguments: parsedArguments)
		} else {
			subparser.printUsage(on: stdoutStream)
		}
	}
}
