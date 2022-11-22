import CodableSQLite
import XCTest

final class SQLDocumentTest: XCTestCase {

    var testObject: SQLDocument!
    var path: String = ""

    override func setUp() async throws {
        try await super.setUp()
        path = try await createTemporarySQLFile()
        testObject = try await SQLDocument(path: path)
    }

    func createTemporaryFile(content: String? = nil) throws -> String {
        let path = "\(FileManager.default.temporaryDirectory.path)temp.txt"
        if !FileManager.default.createFile(atPath: path, contents: content?.data(using: .utf8) ?? Data()) {
            throw CodableSQLError.failedToOpen
        }
        addTeardownBlock {
            do {
                try FileManager.default.removeItem(atPath: path)
                print("Test file removed")
            } catch {
                XCTFail("Failed to delete file")
            }
        }
        return path
    }

    func createTemporarySQLFile(name: String = "/temp.sql") async throws -> String {
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

    func temporarySQLFilePath(name: String) -> String {
        "\(FileManager.default.temporaryDirectory.path)\(name)"
    }

    func test_initWithInvalidPath_thenThrow() async throws {
        do {
            testObject = try await SQLDocument(path: "bad/path")
        } catch {
            return
        }
        XCTFail()
    }

    func test_initNewFile_givenTextFileExist_thenThrow() async throws {
        let path = try createTemporaryFile(content: "Cheese")
        do {
            let _ = try await SQLDocument.init(newfile: path)
        } catch CodableSQLError.invalidFile {
            return
        }
        XCTFail()
    }
}
