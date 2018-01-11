//
//  PBXObject+Extensions.swift
//  bullwinkle
//
//  Created by Geoffrey Foster on 2018-01-11.
//

import Foundation
import XcodeProject

extension ProjectFile {
	func group(forPath path: String?) throws -> PBXGroup {
		let group: PBXGroup
		if let path = path {
			guard let childGroup = project.group(for: path) else {
				throw BullwinkleError.invalidGroup(path)
			}
			group = childGroup
		} else {
			group = project.mainGroup
		}
		return group
	}
}

extension PBXGroup {
	func childGroup(path: [String]) -> PBXGroup? {
		guard !path.isEmpty else {
			return self
		}
		var path = path
		let pathName = path.removeFirst()
		let child = children.flatMap { $0 as? PBXGroup }.first {
			return $0.displayName == pathName
		}
		return child?.childGroup(path: path)
	}
}

extension PBXProject {
	func group(for path: String) -> PBXGroup? {
		let components = path.components(separatedBy: "/")
		return mainGroup.childGroup(path: components)
	}
}
