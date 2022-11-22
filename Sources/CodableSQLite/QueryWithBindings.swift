import Foundation

public class QueryWithBinding: QueryProtocol, QueryBindable {
    public let sql: String
    public let mutable: Bool
    public let bindings: [Any]

    public init(sql: String, mutable: Bool = false, bindings: [Any]) {
        self.sql = sql
        self.mutable = mutable
        self.bindings = bindings
    }

//    public init(insertInto tableName: String, tableRecord: Codable) throws {
//        var workingSql = "INSERT INTO \(tableName) "
//        let json = try JSONEncoder().encode(tableRecord)
//        let dictionary = try JSONSerialization.jsonObject(with: json)
//
//
//    }
}
