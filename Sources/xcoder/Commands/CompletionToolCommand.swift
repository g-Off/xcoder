//
//  CompletionToolCommand.swift
//  xcoder
//
//  Created by Geoffrey Foster on 2018-01-13.
//

import Foundation
import CommandRegistry

public struct CompletionToolCommand: Command {
	private struct Options {
		var completionToolMode: Shell = .bash
	}
	public let command: String = "completion-tool"
	public let overview: String = "Completion tool (for shell completions)"
	private let binder = ArgumentBinder<Options>()
	private let parser: ArgumentParser
	
	public init(parser: ArgumentParser) {
		self.parser = parser
		let subparser = parser.add(subparser: command, overview: overview)
		binder.bind(positional: subparser.add(positional: "mode", kind: Shell.self)) { (options, mode) in
			options.completionToolMode = mode
		}
	}
	
	public func run(with arguments: ArgumentParser.Result) throws {
		var options = Options()
		try binder.fill(parseResult: arguments, into: &options)
		parser.generateCompletionScript(for: options.completionToolMode, on: stdoutStream)
	}
}
