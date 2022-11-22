import Foundation

public class Query: QueryProtocol {
    public let sql: String
    public let mutable: Bool

    public init(sql: String, mutable: Bool = false) {
        self.sql = sql
        self.mutable = mutable
    }
}
