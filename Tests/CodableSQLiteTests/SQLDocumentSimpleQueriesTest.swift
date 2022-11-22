import XCTest
import CodableSQLite

final class SQLDocumentSimpleQueriesTest: XCTestCase {
    var testObject: SQLDocument!

    override func setUp() async throws {
        try await super.setUp()
        let path = try await createTemporarySQLFile()
        testObject = try await SQLDocument(path: path)
    }

    private func createTemporarySQLFile(name: String = "temp.sql") async throws -> String {
        let path = temporarySQLFilePath(name: name)
        let _ = try await SQLDocument(newfile: path)

        addTeardownBlock {
            do {
                try FileManager.default.removeItem(atPath: path)
                print("SQL Test file removed")
            } catch {
                XCTFail("Failed to delete file")
            }
        }
        return path
    }

    private func temporarySQLFilePath(name: String) -> String {
        "\(FileManager.default.temporaryDirectory.path)\(name)"
    }

    func test_exectueQuery_givenCreateTable_thenReturn() async throws {
        let sql = """
        CREATE TABLE IF NOT EXISTS table1 (
            column1 integer PRIMARY KEY,
            column2 text NOT NULL,
            column_3 float DEFAULT 0
        )
"""
        let query = Query(sql: sql, mutable: true)
        do {
            let result = try await testObject.executeQuery(query: query)
            XCTAssertEqual(result.count, 0)
        } catch {
            XCTFail()
        }
    }
}
