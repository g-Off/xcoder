//
//  ArgumentKindExtensions.swift
//  xcoder
//
//  Created by Geoffrey Foster on 2018-01-11.
//

import Foundation
import Utility

extension Foundation.URL: ArgumentKind {
	public static let completion: ShellCompletion = .filename
	
	public init(argument: String) throws {
		self.init(fileURLWithPath: argument)
	}
}

