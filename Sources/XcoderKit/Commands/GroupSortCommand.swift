//
//  GroupSortCommand.swift
//  XcoderKit
//
//  Created by Geoffrey Foster on 2018-12-09.
//

import Foundation
import Utility
import XcodeProject
import Basic
import CommandRegistry

public struct GroupSortCommand: Command {
	private struct SortArguments: XcodeProjectLoading, XcodeReferenceSorting {
		var xcodeproj: AbsolutePath = localFileSystem.currentWorkingDirectory!
		var order: PBXReference.SortOption = .name
		var group: String?
		var recursive: Bool = false
	}
	public let command: String = "group-sort"
	public let overview: String = "Sorts the given group (or top-level)"
	private let binder = ArgumentBinder<SortArguments>()
	
	public init(parser: ArgumentParser) {
		let subparser = parser.add(subparser: command, overview: "Sorts the given group (or top-level)")
		binder.bind(positional: subparser.add(positional: "group", kind: String.self, optional: true, usage: "Group name to sort. For a nested group specify the full path from parent to child with / inbetween.")) { (sortArguments, group) in
			sortArguments.group = group
		}
		binder.bindXcodeProject(parser: subparser)
		binder.bindReferenceSorting(parser: subparser)
		binder.bind(option: subparser.add(option: "--recursive", shortName: "-r", kind: Bool.self, usage: "Recursively descend through all child groups.")) { (sortArguments, recursive) in
			sortArguments.recursive = recursive
		}
	}
	
	public func run(with arguments: ArgumentParser.Result) throws {
		var sortArguments = SortArguments()
		try binder.fill(parseResult: arguments, into: &sortArguments)
		let projectFile = try sortArguments.loadedProject()
		let group = try projectFile.group(forPath: sortArguments.group)
		group.sort(recursive: sortArguments.recursive, by: sortArguments.order)
		try projectFile.save()
	}
}
