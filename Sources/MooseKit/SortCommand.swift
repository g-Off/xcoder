//
//  SortCommand.swift
//  bullwinkle
//
//  Created by Geoffrey Foster on 2018-01-10.
//

import Foundation
import Utility
import XcodeProject

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
	var xcodeproj: Foundation.URL = URL(fileURLWithPath: ".")
	var group: String?
	var order: PBXGroup.SortOption = .name
	var recursive: Bool = false
}

class SortCommand: Command {
	let name: String = "sort"
	let binder = ArgumentBinder<SortArguments>()
	
	required init(parser: ArgumentParser) {
		let subparser = parser.add(subparser: name, overview: "Sorts the given group (or top-level)")
		binder.bind(positional: subparser.add(positional: "xcodeproj", kind: URL.self, optional: false, usage: "Xcode Project file.")) { (sortArguments, xcodeproj) in
			sortArguments.xcodeproj = xcodeproj
		}
		binder.bind(option: subparser.add(option: "--group", shortName: "-g", kind: String.self, usage: "Group name to sort. For a nested group specify the full path from parent to child with / inbetween.")) { (sortArguments, group) in
			sortArguments.group = group
		}
		binder.bind(option: subparser.add(option: "--order", shortName: "-o", kind: PBXGroup.SortOption.self, usage: "Sort the group by one of [\(PBXGroup.SortOption.options.map { $0.name }.joined(separator: ", "))]")) { (sortArguments, order) in
			sortArguments.order = order
		}
		binder.bind(option: subparser.add(option: "--recursive", shortName: "-r", kind: Bool.self, usage: "Recursively descend through all child groups.")) { (sortArguments, recursive) in
			sortArguments.recursive = recursive
		}
	}
	
	func execute(parsedArguments: ArgumentParser.Result) throws {
		var arguments = SortArguments()
		binder.fill(parsedArguments, into: &arguments)
		guard let projectFile = try ProjectFile(url: arguments.xcodeproj) else {
			throw Bullwinkle.Error.invalidProject(path: arguments.xcodeproj.path)
		}
		let group = try projectFile.group(forPath: arguments.group)
		group.sort(recursive: arguments.recursive, by: arguments.order)
		try projectFile.save()
	}
}
