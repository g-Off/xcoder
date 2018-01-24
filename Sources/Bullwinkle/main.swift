import MooseKit
import Foundation

do {
	let command = URL(fileURLWithPath: CommandLine.arguments[0]).lastPathComponent
	try Bullwinkle.execute(command: command, arguments: Array(CommandLine.arguments.dropFirst()))
} catch let error {
	print(error)
}
