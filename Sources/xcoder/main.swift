import Foundation
import CommandRegistry

var registry = Registry(usage: "<command> <options>", overview: "", version: Version.current)
registry.register(command: CompletionToolCommand.self)
registry.register(command: SyncCommand.self)
registry.register(command: GroupSortCommand.self)
registry.register(command: BuildPhaseSortCommand.self)
registry.register(command: SaveCommand.self)
registry.run()
