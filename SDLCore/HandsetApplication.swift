
import Foundation
import SwiftSocket // See: https://github.com/swiftsocket/SwiftSocket

class HandsetApplication {
    private let client: TCPClient
    private var appInterface: Dictionary<String, Any>?
    var isMediaApplication: Bool {
        get {
            guard let appInterface = appInterface else { return false }
            guard let result = appInterface["isMediaApplication"] as? Bool else { return false }
            return result
        }
    }
    var appDisplayName: String {
        get {
            guard let appInterface = appInterface else { return "" }
            guard let appInfo = appInterface["appInfo"] as? Dictionary<String, Any> else { return "" }
            guard let result  = appInfo["appDisplayName"] as? String else { return "" }
            return result
        }
    }
    var appVersion: String {
        get {
            guard let appInterface = appInterface else { return "" }
            guard let appInfo = appInterface["appInfo"] as? Dictionary<String, Any> else { return "" }
            guard let result  = appInfo["appVersion"] as? String else { return "" }
            return result
        }
    }
    init(client: TCPClient) {
        self.client = client
        print("New handset:\(client.address):\(client.port)")
    }
    func processMessages() {
        DispatchQueue.global(qos: .default).async {
            while (true) {
                guard let msg = SDLMessage.read(self.client) else { continue } // Wait here for incoming msg
                switch msg.serviceType {
                case .control: break
                case .rpc:
                    self.handleRPC(msg)
                case .audio: break
                case .video: break
                case .bulkData: break
                }
            }
        }
    }
    func handleStartService(_ msg: SDLMessage) {
        let response = SDLMessage.init(version: msg.version,
                                       compressed: msg.compressed,
                                       frameType: msg.frameType,
                                       serviceType: msg.serviceType,
                                       frameInfo: .startServiceAck,
                                       sessionID: msg.sessionID)
        _ = client.send(data: response.header)
    }
    func handleHeartbeat(_ msg: SDLMessage) {
        do {
            if let dict = try msg.dictionary() {
                if let request = dict["request"] as? Dictionary<String, Any>,
                    let name = request["name"] as? String,
                    let params = request["parameters"] as? Dictionary<String, Any> {
                    //print("\(request)")
                    switch name {
                    case "RegisterAppInterface":
                        print("RegisterAppInterface(\(params))")
                        appInterface = params
                        print("Name....: \(appDisplayName)")
                        print("Version.: \(appVersion)")
                        print("Media...: \(isMediaApplication ? "ENABLED" : "DISABLED")")
                    default: break
                    }
                }
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        let response = SDLMessage.init(version: msg.version,
                                       compressed: msg.compressed,
                                       frameType: msg.frameType,
                                       serviceType: msg.serviceType,
                                       frameInfo: .heartbeatAck,
                                       sessionID: msg.sessionID)
        _ = client.send(data: response.header)
    }
    func handleRPC(_ msg: SDLMessage) {
        switch msg.frameInfo {
        case .heartbeat:
            handleHeartbeat(msg)
        case .startService:
            handleStartService(msg)
        case .endService:
            //client.close()
            break
        case .serviceDataAck: break
        case .heartbeatAck: break
        default: break
        }
    }
}

