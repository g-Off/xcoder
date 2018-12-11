import XcoderKit
import Foundation
import CommandRegistry
import Utility

var registry = Registry(usage: "<command> <options>", overview: "", version: Version.current)
registry.register(command: CompletionToolCommand.self)
registry.register(command: SyncCommand.self)
registry.register(command: GroupSortCommand.self)
registry.register(command: BuildPhaseSortCommand.self)
registry.run()
