//
//  XcodeReferenceSorting.swift
//  XcoderKit
//
//  Created by Geoffrey Foster on 2018-12-10.
//

import Foundation
import XcodeProject
import CommandRegistry

extension PBXReference.SortOption: StringEnumArgument {
	static var options: [(name: String, description: String)] = [
		(name: PBXReference.SortOption.name.rawValue, description: "Sort by name"),
		(name: PBXReference.SortOption.type.rawValue, description: "Sort by type")
	]
	public static var completion: ShellCompletion {
		return .values(options.map { (value: $0.name, description: $0.description) })
	}
}

protocol XcodeReferenceSorting {
	var order: PBXReference.SortOption { get set }
}

extension XcodeReferenceSorting {

}

extension ArgumentBinder where Options: XcodeReferenceSorting {
	func bindReferenceSorting(parser: ArgumentParser) {
		let option = parser.add(option: "--order", shortName: "-o", kind: PBXReference.SortOption.self, usage: "Sort the group by one of [\(PBXGroup.SortOption.options.map { $0.name }.joined(separator: ", "))]")
		bind(option: option) { (options, order) in
			options.order = order
		}
	}
}
