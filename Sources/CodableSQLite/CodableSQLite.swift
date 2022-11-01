import Foundation
import SQLite3

public protocol CodableSQLiteAPI {
    func setFile(path: String) async throws
    func executeDataQuery(query: QueryProtocol) async throws -> Data
    func executeQuery(query: QueryProtocol) async throws -> [[String: Codable]]
}

public actor CodableSQLite: CodableSQLiteAPI {
    var filePath: String?

    public func setFile(path: String) async throws {
        if FileManager.default.fileExists(atPath: path) {
            filePath = path
        } else {
            throw(CodableSQLError.fileNotFound)
        }
    }

    public init() {}

    public init(path: String) async throws {
        try await setFile(path: path)
    }

    public func executeDataQuery(query: QueryProtocol) async throws -> Data {
        let result = try await executeQuery(query: query)
        return try JSONSerialization.data(withJSONObject: result, options: .prettyPrinted)
    }

    public func executeQuery(query: QueryProtocol) async throws -> [[String: Codable]] {
        let theFile = try openDB()
        var theStmt: OpaquePointer?
        let prepareResult = sqlite3_prepare_v2(theFile, query.sql, -1, &theStmt, nil)

        guard let stmt = theStmt else {
            let message: String = String(cString: sqlite3_errmsg(theFile))
            closeDB(theFile)
            throw(CodableSQLError.sqliteStatementError(message))
        }

        if prepareResult != SQLITE_OK {
            try processSQLiteError(file: theFile)
        }

        sqlite3_reset(stmt)
        if let bindableQuery = query as? QueryBindable {
            let bindings = bindableQuery.bindings
            try bind(bindings: bindings, statement: stmt)
        }
        var rowData = [[String: Codable]]()
        while sqlite3_step(stmt) == SQLITE_ROW {
            rowData.append(processRow(theStmt: stmt))
        }
        let error = sqlite3_errcode(theFile)
        if error != SQLITE_OK && error != SQLITE_DONE {
            print(#function)
            print("code \(error)")
            print(String(cString: sqlite3_errstr(error)))
        }
        sqlite3_finalize(stmt)
        closeDB(theFile)
        print(rowData)
        return rowData
    }

    // MARK: Private API
    private func openDB() throws -> OpaquePointer {

        var theFile: OpaquePointer?
        let returnCode = sqlite3_open_v2(filePath, &theFile, SQLITE_OPEN_READONLY, nil)
        guard let file = theFile, returnCode == SQLITE_OK else {
            throw(CodableSQLError.failedToOpen)
        }
        return file
    }

    private func processSQLiteError(file: OpaquePointer) throws {
        let message: String = String(cString: sqlite3_errmsg(file))
        closeDB(file)
        throw(CodableSQLError.sqliteError(message))
    }

    private func closeDB(_ theFile: OpaquePointer?) {
        guard let file = theFile else { return }
        sqlite3_close_v2(file)
    }

    private func bind(bindings: [Any], statement: OpaquePointer) throws {
        for (index, binding) in bindings.enumerated() {
            let currentIndex = Int32(index + 1)
            var result: Int32 = 0
            switch binding {
            case let value as Int:
                result = sqlite3_bind_int(statement, currentIndex, Int32(value))
            case let value as Int32:
                result = sqlite3_bind_int(statement, currentIndex, value)
            case let value as UInt:
                result = sqlite3_bind_int(statement, currentIndex, Int32(value))
            case let value as UInt32:
                result = sqlite3_bind_int(statement, currentIndex, Int32(value))
            case let value as Float:
                result = sqlite3_bind_double(statement, currentIndex, Double(value))
            case let value as Double:
                result = sqlite3_bind_double(statement, currentIndex, value)
            case let value as String:
                result = sqlite3_bind_text(statement,
                                           currentIndex,
                                           (value as NSString).utf8String,
                                           -1,
                                           nil)

            default:
                break
            }
            if result != SQLITE_OK {
                let message: String = String(cString: sqlite3_errstr(result))
                throw(CodableSQLError.sqliteBindingError(message))
            }
        }
    }

    private func processRow(theStmt: OpaquePointer) -> [String: Codable] {
        var aRecord = [String: Codable]()
        let count = sqlite3_column_count(theStmt)
        for i in 0 ..< count {
            if let columnString = String(validatingUTF8: sqlite3_column_name(theStmt, i)) {
                let columnType = sqlite3_column_type(theStmt, i)
                switch columnType {
                case SQLITE_INTEGER:
                    let baseValue = sqlite3_column_int(theStmt, i)
                    aRecord[columnString] = baseValue
                case SQLITE_FLOAT:
                    let baseValue = sqlite3_column_double(theStmt, i)
                    aRecord[columnString] = baseValue
                case SQLITE_BLOB:
                    let length = sqlite3_column_bytes(theStmt, i)
                    if let pointer = UnsafeRawPointer(sqlite3_column_blob(theStmt, i)) {
                        let tempData = Data.init(bytes: pointer, count: Int(length))
                        aRecord[columnString] = tempData.base64EncodedString()
                    }
                case SQLITE_TEXT:
                    if let pointer = UnsafeRawPointer(sqlite3_column_text(theStmt, i)) {
                        let tempString: String = String.init(cString: pointer.assumingMemoryBound(to: CChar.self))
                        aRecord[columnString] = tempString
                    }

                case  SQLITE_NULL:
                    ()
                default:
                    print("\(columnString) \(columnType)")// do not handle
                }
            }
        }
        return aRecord
    }
}
