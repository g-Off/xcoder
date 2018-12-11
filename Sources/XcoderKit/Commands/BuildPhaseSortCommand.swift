//
//  BuildPhaseSortCommand.swift
//  XcoderKit
//
//  Created by Geoffrey Foster on 2018-12-09.
//

import Foundation
import Utility
import XcodeProject
import Basic
import CommandRegistry

public struct BuildPhaseSortCommand: Command {
	private struct SortArguments: XcodeProjectLoading, XcodeReferenceSorting {
		enum BuildPhase: String, StringEnumArgument {
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
		
		var xcodeproj: AbsolutePath = localFileSystem.currentWorkingDirectory!
		var order: PBXReference.SortOption = .name
		var target: String?
		var phase: BuildPhase = .sources
		var overrides: [String] = []
	}
	public let command: String = "phase-sort"
	public let overview: String = "Sorts the given phase (or top-level)"
	private let binder = ArgumentBinder<SortArguments>()
	
	public init(parser: ArgumentParser) {
		let subparser = parser.add(subparser: command, overview: overview)
		binder.bind(positional: subparser.add(positional: "phase", kind: SortArguments.BuildPhase.self, optional: true, usage: "Name of the build phase to sort.")) { (sortArguments, phase) in
			sortArguments.phase = phase
		}
		binder.bindXcodeProject(parser: subparser)
		binder.bindReferenceSorting(parser: subparser)
		binder.bind(option: subparser.add(option: "--target", shortName: "-t", kind: String.self, usage: "Name of the target.")) { (sortArguments, target) in
			sortArguments.target = target
		}
		binder.bindArray(option: subparser.add(option: "--override-group", kind: [String].self, strategy: .upToNextOption)) { (sortArguments, overrides) in
			sortArguments.overrides = overrides
		}
	}
	
	public func run(with arguments: ArgumentParser.Result) throws {
		func findTarget(from projectFile: ProjectFile, named targetName: String?) throws -> PBXTarget {
			let foundTarget: PBXTarget?
			if let targetName = targetName {
				foundTarget = projectFile.project.targets.first { $0.name == targetName }
			} else {
				foundTarget = projectFile.project.targets.first
			}
			guard let target = foundTarget else {
				throw Error.invalidTarget(targetName ?? "No target specified")
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
		var sortArguments = SortArguments()
		try binder.fill(parseResult: arguments, into: &sortArguments)
		let projectFile = try sortArguments.loadedProject()
		
		let overrideGroups = try sortArguments.overrides.compactMap { try projectFile.group(forPath: $0) }
		let target = try findTarget(from: projectFile, named: sortArguments.target)
		if let phase = target.buildPhases.first(where: { sortArguments.phase.matches(buildPhase: $0) }) {
			sort(phase: phase, order: sortArguments.order, overrides: overrideGroups)
		} else {
			target.buildPhases.forEach { phase in
				guard SortArguments.BuildPhase.frameworks.matches(buildPhase: phase) ||
					SortArguments.BuildPhase.headers.matches(buildPhase: phase) ||
					SortArguments.BuildPhase.resources.matches(buildPhase: phase) ||
					SortArguments.BuildPhase.sources.matches(buildPhase: phase) else {
						return
				}
				sort(phase: phase, order: sortArguments.order, overrides: overrideGroups)
			}
		}
		try projectFile.save()
	}
}
