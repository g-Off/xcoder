import Foundation
import Utility
import Basic
import XcodeProject

let parser = ArgumentParser(commandName: "bullwinkle", usage: "[subcommand]", overview: "run and install Swift PM executables")
let versionArgument = parser.add(option: "--version", shortName: "-v", kind: Bool.self, usage: "Prints the current version of Mint")

let commands: [Command] = [
	SortCommand(parser: parser),
	SyncCommand(parser: parser)
]

let arguments = Array(CommandLine.arguments.dropFirst())
do {
	let parsedArguments = try parser.parse(arguments)
	
	if let printVersion = parsedArguments.get(versionArgument), printVersion == true {
		print(Version(0, 1, 0))
		exit(0)
	}
	
	if let subParser = parsedArguments.subparser(parser) {
		let command = commands.first { $0.name == subParser }
		try command?.execute(parsedArguments: parsedArguments)
	} else {
		parser.printUsage(on: stdoutStream)
	}
} catch ArgumentParserError.expectedValue(let value) {
	print("Missing value for argument \(value).")
} catch ArgumentParserError.expectedArguments(let parser, let arguments) {
	print("Missing arguments: \(arguments.joined()).")
	parser.printUsage(on: stdoutStream)
} catch let error {
	print(error)
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
