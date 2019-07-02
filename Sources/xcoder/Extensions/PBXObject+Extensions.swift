//
//  PBXObject+Extensions.swift
//  xcoder
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
				throw Error.invalidGroup(path)
			}
			group = childGroup
		} else {
			group = project.mainGroup
		}
		return group
	}
	
	func buildPhase(named name: String) throws -> [PBXBuildPhase] {
		guard let target = project.target(named: "") else {
			throw Error.invalidTarget("")
		}
		
		return target.buildPhases.filter {
			$0.name == name
		}
	}
}

extension PBXGroup {
	func childGroup(path: [String]) -> PBXGroup? {
		guard !path.isEmpty else {
			return self
		}
		var path = path
		let pathName = path.removeFirst()
		let child = childGroups.first {
			return $0.displayName == pathName
		}
		return child?.childGroup(path: path)
	}
	
	var childGroups: [PBXGroup] {
		return children.compactMap { $0 as? PBXGroup }
	}
	
	func contains(_ reference: PBXReference, recursive: Bool) -> Bool {
		if let _ = children.first(where: { $0 == reference }) {
			return true
		}
		if recursive {
			if let _ = childGroups.first(where: { $0.contains(reference, recursive: recursive) }) {
				return true
			}
		}
		return false
	}
	
}

extension PBXProject {
	func group(for path: String) -> PBXGroup? {
		let components = path.components(separatedBy: "/")
		return mainGroup.childGroup(path: components)
	}
}
