import Foundation

public enum CodableSQLError: Error {
    case sqliteError(String)
    case sqliteStatementError(String)
    case sqliteBindingError(String)
    case fileNotFound
    case decodeFailure
    case failedToOpen
    case invalidFile
}
