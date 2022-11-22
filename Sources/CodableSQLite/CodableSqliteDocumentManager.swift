import Foundation
import SQLite3

public class CodableSqliteDocumentManager {
    private let fileManager: FileManager
    private var documents: [String: SQLDocument] = [:]


    public nonisolated init(fileManager: FileManager = FileManager.default) {
        self.fileManager = fileManager
    }

    public func document(for path: String) async throws -> SQLDocument {
        if let document = documents[path] {
            return document
        }
        try verifyFileExists(at: path)

        return try await openDocument(at: path)
    }

    public func newDocument(at path: String) async throws -> SQLDocument {
        if let document = documents[path] {
            return document
        }
        do {
            try verifyFileExists(at: path)
        } catch {
            return try await openNewDocument(at: path)
        }
        return try await openDocument(at: path)
    }

    // MARK: - Private API

    private func openDocument(at path: String) async throws -> SQLDocument {
        let file = try await SQLDocument(path: path)
        documents[path] = file
        return file
    }

    private func openNewDocument(at path: String) async throws -> SQLDocument {
        let file = try await SQLDocument(newfile: path)
        documents[path] = file
        return file
    }

    private func verifyFileExists(at path: String) throws {
        if !fileManager.fileExists(atPath: path) {
            throw CodableSQLError.fileNotFound
        }
    }
}
