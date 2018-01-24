//
//  Command.swift
//  bullwinkle
//
//  Created by Geoffrey Foster on 2018-01-10.
//

import Utility
import Foundation
import XcodeProject

protocol Command {
	var name: String { get }
	
	init(parser: ArgumentParser)
	func execute(parsedArguments: ArgumentParser.Result) throws
}
