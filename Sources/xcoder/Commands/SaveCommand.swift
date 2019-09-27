//
//  SaveCommand.swift
//  XcoderKit
//
//  Created by Geoffrey Foster on 2019-05-02.
//

import Foundation
import XcodeProject
import CommandRegistry

public struct SaveCommand: Command {
	private struct SaveArguments {
		var xcodeProjects: [AbsolutePath] = [localFileSystem.currentWorkingDirectory!]
	}
	
	public let command: String = "save"
	public let overview: String = "Saves the Xcode project."
	private let binder = ArgumentBinder<SaveArguments>()
	
	public init(parser: ArgumentParser) {
		let subparser = parser.add(subparser: command, overview: overview)
		binder.bind(positional: subparser.add(positional: "xcodeproj", kind: [PathArgument].self, optional: false, usage: "Xcode Project file.", completion: .filename)) { (syncArguments, xcodeProjects) in
			syncArguments.xcodeProjects = xcodeProjects.map { $0.path }
		}
	}
	
	public func run(with parsedArguments: ArgumentParser.Result) throws {
		var arguments = SaveArguments()
		try binder.fill(parseResult: parsedArguments, into: &arguments)
		
		for path in arguments.xcodeProjects {
			let projectFile: ProjectFile
			do {
				projectFile = try ProjectFile(url: Foundation.URL(fileURLWithPath: path.asString))
			} catch {
				throw Error.invalidProject(path: path.asString)
			}
			try projectFile.save()
		}
	}
}
