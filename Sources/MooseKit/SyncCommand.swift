//
//  SortCommand.swift
//  bullwinkle
//
//  Created by Geoffrey Foster on 2018-01-10.
//

import Foundation
import Utility
import XcodeProject

final class SyncArguments {
	var xcodeproj: Foundation.URL = URL(fileURLWithPath: ".")
	var group: String?
	var targetName: String?
	var recursive: Bool = false
}

class SyncCommand: Command {
	let name: String = "sync"
	let binder = ArgumentBinder<SyncArguments>()
	
	required init(parser: ArgumentParser) {
		let subparser = parser.add(subparser: name, overview: "Sync the Xcode project groups with the filesystem.")
		binder.bind(positional: subparser.add(positional: "xcodeproj", kind: URL.self, optional: false, usage: "Xcode Project file.")) { (syncArguments, xcodeproj) in
			syncArguments.xcodeproj = xcodeproj
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
	
	func execute(parsedArguments: ArgumentParser.Result) throws {
		var arguments = SyncArguments()
		binder.fill(parsedArguments, into: &arguments)
		
		guard let projectFile = try ProjectFile(url: arguments.xcodeproj) else {
			throw Bullwinkle.Error.invalidProject(path: arguments.xcodeproj.path)
		}
		let group = try projectFile.group(forPath: arguments.group)
		
		var target: PBXTarget?
		if let targetName = arguments.targetName {
			guard let targetNamed = projectFile.project.target(named: targetName) else {
				throw Bullwinkle.Error.invalidTarget(targetName)
			}
			target = targetNamed
		}
		
		group.sync(recursive: arguments.recursive, target: target)
		try projectFile.save()
	}
}
