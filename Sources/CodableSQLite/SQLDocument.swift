import Foundation
import OSLog
import SQLite3

public actor SQLDocument {
    var filePath: String

    public init(path: String) async throws {
        filePath = path
        try isSqlite()
    }

    public init(newfile: String) async throws {
        filePath = newfile
        try createFile(at: newfile)
    }

    func isSqlite() throws {
        try verifySQLFile(path: filePath)
    }

    // MARK: - File Management

    private func createFile(at path: String, fileManager: FileManager = FileManager.default) throws {
        var theFile: OpaquePointer?
        if fileManager.fileExists(atPath: path) {
            try isSqlite()
            return
        }
        let returnCode = sqlite3_open_v2(filePath, &theFile, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, nil)
        guard let file = theFile, returnCode == SQLITE_OK else {
            throw(CodableSQLError.failedToOpen)
        }
        closeDB(file)
    }

    private func openDB(mutable: Bool) throws -> OpaquePointer {
        var theFile: OpaquePointer?
        let returnCode = sqlite3_open_v2(filePath, &theFile, mutable ? SQLITE_OPEN_READWRITE : SQLITE_OPEN_READONLY, nil)
        guard let file = theFile, returnCode == SQLITE_OK else {
            throw(CodableSQLError.failedToOpen)
        }
        return file
    }
    
    private func closeDB(_ theFile: OpaquePointer?) {
        guard let file = theFile else { return }
        sqlite3_close_v2(file)
    }

    private func verifySQLFile(path: String) throws {
        let magicString = "SQLite format 3"
        // Empty file could be valid
        guard let handle = FileHandle(forReadingAtPath: path) else {
            throw CodableSQLError.invalidFile
        }
        if try fileSize() == 0 {
            try handle.close()
            return
        }
        guard let content = try handle.read(upToCount: 15) else {
            try handle.close()
            throw CodableSQLError.invalidFile
        }
        let bytesString = String(data: content, encoding: .utf8)
        if bytesString != magicString {
            throw CodableSQLError.invalidFile
        }
    }

    private func fileSize() throws -> UInt64 {
        let attr = try FileManager.default.attributesOfItem(atPath: filePath)
        if let fileSize = attr[FileAttributeKey.size] as? UInt64 {
            return fileSize
        }
        throw CodableSQLError.invalidFile
    }

    // MARK: - Error

    private func processSQLiteError(file: OpaquePointer) throws {
        let message: String = String(cString: sqlite3_errmsg(file))
        closeDB(file)
        throw(CodableSQLError.sqliteError(message))
    }

    // MARK: - Run Query

    public func executeDataQuery(query: QueryProtocol) async throws -> Data {
        let result = try await executeQuery(query: query)
        return try JSONSerialization.data(withJSONObject: result, options: .prettyPrinted)
    }

    public func executeQuery(query: QueryProtocol) async throws -> [[String: Codable]] {
        let theFile = try openDB(mutable: query.mutable)
        let stmt = try prepare(file: theFile, sql: query.sql)
        defer {
            sqlite3_finalize(stmt)
            closeDB(theFile)

        }

        try reset(file: theFile, statement: stmt)
        try bind(query: query, statement: stmt)

        return try process(file: theFile, statement: stmt)
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
                    Logger.codableLog.error("\(columnString) \(columnType)")
                }
            }
        }
        return aRecord
    }

    private func reset(file: OpaquePointer, statement: OpaquePointer) throws {
        let error = sqlite3_reset(statement)
        if error != SQLITE_OK {
            try processSQLiteError(file: file)
        }
    }

    private func prepare(file: OpaquePointer, sql: String) throws -> OpaquePointer {
        var theStmt: OpaquePointer?
        let prepareResult = sqlite3_prepare_v2(
            file,
            sql,
            -1,
            &theStmt,
            nil)

        if prepareResult != SQLITE_OK {
            try processSQLiteError(file: file)
        }

        guard let stmt = theStmt else {
            let message: String = String(cString: sqlite3_errmsg(file))
            closeDB(file)
            throw(CodableSQLError.sqliteStatementError(message))
        }
        return stmt
    }

    private func bind(query: QueryProtocol, statement: OpaquePointer) throws {
        if let bindableQuery = query as? QueryBindable {
            let bindings = bindableQuery.bindings
            try bind(bindings: bindings, statement: statement)
        }
    }

    private func process(file: OpaquePointer, statement: OpaquePointer) throws -> [[String: Codable]] {
        var rowData = [[String: Codable]]()
        while sqlite3_step(statement) == SQLITE_ROW {
            rowData.append(processRow(theStmt: statement))
        }
        let error = sqlite3_errcode(file)
        if error != SQLITE_OK && error != SQLITE_DONE {
            try processSQLiteError(file: file)
        }
        return rowData
    }

}
