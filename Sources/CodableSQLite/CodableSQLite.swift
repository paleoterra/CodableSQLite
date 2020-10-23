import Foundation
import SQLite3

public class CodableSQLite {
    let filePath: String!

    public init(path: String) {
        self.filePath = path
    }

    public func executeDataQuery(query: QueryProtocol) -> Data? {
        guard let result = executeQuery(query: query) else { return nil }
        return try? JSONSerialization.data(withJSONObject: result, options: .prettyPrinted)
    }

    public func executeQuery(query: QueryProtocol) -> [[String: Codable]]? {
        guard let theFile = openDB() else { return nil }
        var theStmt: OpaquePointer? = nil
        let prepareResult = sqlite3_prepare_v2(theFile, query.sql, -1, &theStmt, nil)
        guard let stmt = theStmt, prepareResult == SQLITE_OK else {
            closeDB(theFile)
            return nil
        }
        sqlite3_reset(stmt)
        if let bindableQuery = query as? QueryBindable {
            let bindings = bindableQuery.bindings
            bind(bindings: bindings, statement: stmt)
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
            sqlite3_finalize(stmt)
        }
        closeDB(theFile)
        return rowData
    }

    // MARK: Private API
    private func openDB()  -> OpaquePointer? {

        var  theFile: OpaquePointer? = nil
        let returnCode = sqlite3_open_v2(filePath,&theFile,SQLITE_OPEN_READONLY,nil)
        if returnCode != SQLITE_OK {
            return nil
        }
        return theFile
    }

    private func closeDB(_ theFile: OpaquePointer?) {
        guard let file = theFile else { return }
        sqlite3_close_v2(file)
    }

    private func bind(bindings: [Any], statement: OpaquePointer) {
        for (index, binding) in bindings.enumerated() {
            let currentIndex = Int32(index + 1)
            var result: Int32 = 0
            switch(binding) {
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
                                           value.cString(using: .utf8),
                                           -1,
                                           nil)

            default:
                break;
            }
            if result != SQLITE_OK {
                print("error")
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
                    print("\(columnString) \(columnType)")//do not handle
                }
            }
        }
        return aRecord
    }
}
