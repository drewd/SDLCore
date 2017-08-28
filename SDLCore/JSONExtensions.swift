
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
    static func create(fromJSONFile url: URL) throws -> Dictionary? {
        do {
            let data = try Data.init(contentsOf: url)
            return try JSONSerialization.jsonObject(with: data as Data, options: .mutableContainers) as? Dictionary
        } catch let error as NSError {
            print(error)
        }
        return nil
    }
    func jsonString() throws -> String? {
        var ret: String = String()
        do {
            let json = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            ret = String(data: json, encoding: String.Encoding.utf8) ?? ""
        } catch let error as NSError {
            print(error)
        }
        return ret
    }
    func jsonData() throws -> Data? {
        var ret: Data = Data()
        do {
            let json = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            ret = json
        } catch let error as NSError {
            print(error)
        }
        return ret
    }
}

extension Data {
    func jsonString() throws -> String? {
        var ret: String = String()
        do {
            if let dict = try Dictionary<String, Any>.create(fromJSONData: self) {
                let json = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
                ret = String(data: json, encoding: String.Encoding.utf8) ?? ""
            }
        } catch let error as NSError {
            print(error)
        }
        return ret
    }
}

extension Array {
    func jsonString() throws -> String? {
        var ret: String = String()
        do {
            let json = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            ret = String(data: json, encoding: String.Encoding.utf8) ?? ""
        } catch let error as NSError {
            print(error)
        }
        return ret
    }
    func jsonData() throws -> Data? {
        var ret: Data = Data()
        do {
            let json = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            ret = json
        } catch let error as NSError {
            print(error)
        }
        return ret
    }
}

// TODO: MoveMe
extension UInt32 {
    static func create(fromData data: [UInt8]) -> UInt32 { // Swaps BE<->LE
        let ret = (UInt32(data[3]) << 24) |
            (UInt32(data[2]) << 16) |
            (UInt32(data[1]) << 8) |
            UInt32(data[0])
        return ret
    }
}

extension Data {
    static func from(uint32: UInt32) -> Data { // Swaps BE<->LE
        var val = Data.init(count: 4)
        val[0] = UInt8((uint32 >> 24) & 0xff)
        val[1] = UInt8((uint32 >> 16) & 0xff)
        val[2] = UInt8((uint32 >> 8) & 0xff)
        val[3] = UInt8(uint32 & 0xff)
        return val
    }
}
