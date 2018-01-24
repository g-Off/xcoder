//
//  Bullwinkle.swift
//  bullwinkle
//
//  Created by Geoffrey Foster on 2018-01-13.
//

import Foundation
import Utility
import Basic

public final class Bullwinkle {
	public static let version = Version(0, 1, 0)
	enum Error: Swift.Error, CustomStringConvertible {
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
	
	struct Options {
		public var shouldPrintVersion: Bool = false
	}
	
	public static func execute(command: String, arguments: [String]) throws {
		let parser = ArgumentParser(commandName: command, usage: "[subcommand]", overview: "sort and sync Xcode project groups")
		
		let binder = ArgumentBinder<Options>()
		binder.bind(option: parser.add(option: "--version", shortName: "-v", kind: Bool.self, usage: "Prints the current version of \(command.capitalized)")) { (options, shouldPrintVersion) in
			options.shouldPrintVersion = shouldPrintVersion
		}
		
		let commands: [Command] = [
			SortCommand(parser: parser),
			SyncCommand(parser: parser),
			CompletionToolCommand(parser: parser)
		]
		
		let parsedArguments = try parser.parse(arguments)
		
		var options = Options()
		binder.fill(parsedArguments, into: &options)
		
		if options.shouldPrintVersion {
			print(Bullwinkle.version)
			exit(0)
		}
		
		if let subParser = parsedArguments.subparser(parser),
			let command = commands.first(where : { $0.name == subParser }) {
			do {
				try command.execute(parsedArguments: parsedArguments)
			} catch ArgumentParserError.expectedValue(let value) {
				print("Missing value for argument \(value).")
			} catch ArgumentParserError.expectedArguments(let parser, let arguments) {
				print("Missing arguments: \(arguments.joined()).")
				parser.printUsage(on: stdoutStream)
			}
		} else {
			parser.printUsage(on: stdoutStream)
		}
	}
}
