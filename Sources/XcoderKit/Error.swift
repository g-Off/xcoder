//
//  Error.swift
//  xcoder
//
//  Created by Geoffrey Foster on 2018-01-13.
//

import Foundation

enum Error: Swift.Error, CustomStringConvertible {
	case invalidProject(path: String?)
	case invalidGroup(String)
	case invalidTarget(String)
	
	var description: String {
		switch self {
		case .invalidProject(let path):
			if let path = path {
				return "Invalid project at \(path)"
			} else {
				return "No project specified"
			}
		case .invalidGroup(let groupPath):
			return "Invalid group path \(groupPath)"
		case .invalidTarget(let targetName):
			return "Invalid target \(targetName)"
		}
	}
}
