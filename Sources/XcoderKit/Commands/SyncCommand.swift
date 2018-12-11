//
//  SortCommand.swift
//  xcoder
//
//  Created by Geoffrey Foster on 2018-01-10.
//

import Foundation
import Utility
import Basic
import XcodeProject
import CommandRegistry

public struct SyncCommand: Command {
	private struct SyncArguments {
		var xcodeproj: AbsolutePath = localFileSystem.currentWorkingDirectory!
		var group: String?
		var targetName: String?
		var recursive: Bool = false
	}
	
	public let command: String = "sync"
	public let overview: String = "Sync the Xcode project groups with the filesystem."
	private let binder = ArgumentBinder<SyncArguments>()
	
	public init(parser: ArgumentParser) {
		let subparser = parser.add(subparser: command, overview: overview)
		binder.bind(positional: subparser.add(positional: "xcodeproj", kind: PathArgument.self, optional: false, usage: "Xcode Project file.", completion: .filename)) { (syncArguments, xcodeproj) in
			syncArguments.xcodeproj = xcodeproj.path
		}
		binder.bind(option: subparser.add(option: "--group", shortName: "-g", kind: String.self, usage: "Group name to sync. For a nested group specify the full path from parent to child with / inbetween.")) { (syncArguments, group) in
			syncArguments.group = group
		}
		binder.bind(option: subparser.add(option: "--target", shortName: "-t", kind: String.self, usage: "Target to add new files")) { (syncArguments, targetName) in
			syncArguments.targetName = targetName
		}
		binder.bind(option: subparser.add(option: "--recursive", shortName: "-r", kind: Bool.self, usage: "Recursively descend through all child groups.")) { (syncArguments, recursive) in
			syncArguments.recursive = recursive
		}
	}
	
	public func run(with parsedArguments: ArgumentParser.Result) throws {
		var arguments = SyncArguments()
		try binder.fill(parseResult: parsedArguments, into: &arguments)
		
		let projectFile: ProjectFile
		do {
			projectFile = try ProjectFile(url: Foundation.URL(fileURLWithPath: arguments.xcodeproj.asString))
		} catch {
			throw Error.invalidProject(path: arguments.xcodeproj.asString)
		}
		let group = try projectFile.group(forPath: arguments.group)
		
		var target: PBXTarget?
		if let targetName = arguments.targetName {
			guard let targetNamed = projectFile.project.target(named: targetName) else {
				throw Error.invalidTarget(targetName)
			}
			target = targetNamed
		}
		
		group.sync(recursive: arguments.recursive, target: target)
		try projectFile.save()
	}
}
