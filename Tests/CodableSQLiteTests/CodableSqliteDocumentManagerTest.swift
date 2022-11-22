import CodableSQLite
import Foundation
import XCTest

class CodableSqliteDocumentManagerTest: XCTestCase {
    var testObject: CodableSqliteDocumentManager!
    var mockFileManager = MockFileManager()

    override func setUp() async throws {
        try await super.setUp()
        testObject = CodableSqliteDocumentManager(fileManager: mockFileManager)
    }

    private func createTemporaryFile() throws -> String {
        let path = "\(FileManager.default.temporaryDirectory.path)temp.txt"
        if !FileManager.default.createFile(atPath: path, contents: Data()) {
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

    func test_init() {
        XCTAssertNotNil(testObject)
    }

    func test_documentAt_givenInvalidPath_thenThrow() async throws {
        mockFileManager.fileExistsAtPathOverrideValue = false
        do {
            let _ = try await testObject.document(for: "test/path")
        } catch CodableSQLError.fileNotFound {
            return
        }
        XCTFail()
    }

    func test_documentAt_givenValidPathWithNonSQLFile_thenThrow() async throws {
        let tempFile = try createTemporaryFile()
        do {
            let _ = try await SQLDocument(path: tempFile)
        } catch CodableSQLError.failedToOpen {
            return
        } catch {
            XCTFail()
        }
    }

    func test_documentAt_givenValidPathWithSQLFile_thenSucceed() async throws {
        let tempFile = try await createTemporarySQLFile()
        do {
            let _ = try await SQLDocument(path: tempFile)
        } catch {
            XCTFail()
        }
    }

    func test_documentFor_givenDocumentExists_thenReturnSameDocument() async throws {
        let tempfilePath = try createTemporaryFile()
        let document1 = try await testObject.document(for: tempfilePath)
        let document2 = try await testObject.document(for: tempfilePath)
        XCTAssertTrue(document1 === document2)
    }

    func test_documentFor_givenTwoDocumentExists_thenReturnDifferntDocuments() async throws {
        let tempfilePath = try await createTemporarySQLFile()
        let tempfilePath2 = try await createTemporarySQLFile(name: "temp2.sql")
        let document1 = try await testObject.document(for: tempfilePath)
        let document2 = try await testObject.document(for: tempfilePath2)
        let document3 = try await testObject.document(for: tempfilePath2)
        XCTAssertFalse(document1 === document2)
        XCTAssertFalse(document1 === document3)
        XCTAssertTrue(document2 === document3)
    }

    func test_newDocumentAt_givenPath_thenCreateFile() async throws {
        let tempPath = temporarySQLFilePath(name: "/test.sql")
        let _ = try await testObject.newDocument(at: tempPath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempPath))
        try FileManager.default.removeItem(atPath: tempPath)
    }

    func test_newDocumentAt_givenPathTwice_thenCreateFileOnce() async throws {
        let tempPath = temporarySQLFilePath(name: "/test.sql")
        let document1 = try await testObject.newDocument(at: tempPath)
        let document2 = try await testObject.newDocument(at: tempPath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempPath))
        try FileManager.default.removeItem(atPath: tempPath)
        XCTAssertTrue(document1 === document2)
    }

    func test_createNewDocument_givenDocumentAlreadyExists_thenReturn() async throws {
        let tempPath = try await createTemporarySQLFile()
        let _ = try await testObject.newDocument(at: tempPath)
    }
}
