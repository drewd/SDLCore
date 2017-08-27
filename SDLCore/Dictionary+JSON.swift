
import Foundation

extension Dictionary {
    static func create(fromJSONData data: Data) throws -> Dictionary? {
        do {
            return try JSONSerialization.jsonObject(with: data as Data, options: .mutableContainers) as? Dictionary
        } catch let error as NSError {
            print(error)
        }
        return nil
    }
}
