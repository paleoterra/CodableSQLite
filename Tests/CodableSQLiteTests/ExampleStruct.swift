import Foundation
import CodableSQLite

struct ExampleStruct: Codable, MutableSQLType {
    var id: Int?
    var name: String
    var value: Float

    static var primaryKey = "id"

}
