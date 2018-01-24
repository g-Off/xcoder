//
//  CompletionToolCommand.swift
//  bullwinkle
//
//  Created by Geoffrey Foster on 2018-01-13.
//

import Foundation
import Utility
import Basic

class CompletionToolCommand: Command {
	struct Options {
		var completionToolMode: Shell = .bash
	}
	let name: String = "completion-tool"
	let binder = ArgumentBinder<Options>()
	let parser: ArgumentParser
	
	required init(parser: ArgumentParser) {
		self.parser = parser
		let completionToolParser = parser.add(subparser: name, overview: "Completion tool (for shell completions)")
		let f = completionToolParser.add(positional: "mode", kind: Shell.self)
		binder.bind(positional: f) { (options, mode) in
			options.completionToolMode = mode
		}
	}
	
	func execute(parsedArguments: ArgumentParser.Result) throws {
		var options = Options()
		binder.fill(parsedArguments, into: &options)

		parser.generateCompletionScript(for: options.completionToolMode, on: stdoutStream)
	}
}
