import Foundation

class MockFileManager: FileManager {

    var fileExistsAtPathOverrideValue: Bool?
    override func fileExists(atPath path: String) -> Bool {
        if let returnValue = fileExistsAtPathOverrideValue {
            return returnValue
        }
        return super.fileExists(atPath: path)
    }
}
