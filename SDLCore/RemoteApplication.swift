
import Foundation
import SwiftSocket // See: https://github.com/swiftsocket/SwiftSocket

class RemoteApplication {
    fileprivate let client: TCPClient
    fileprivate var appInterface: Dictionary<String, Any>?
    fileprivate var recvMessageID: UInt32 = 0
    fileprivate var sendMessageID: UInt32 = 0
    fileprivate let videoProjection = VideoProjectionReceiver()
    var isAudible = false
    var isMediaApplication: Bool {
        get {
            guard let appInterface = appInterface else { return false }
            guard let result = appInterface["isMediaApplication"] as? Bool else { return false }
            return result
        }
    }
    var appBundleID: String {
        get {
            guard let appInterface = appInterface else { return "" }
            guard let appInfo = appInterface["appInfo"] as? Dictionary<String, Any> else { return "" }
            guard let result  = appInfo["appBundleID"] as? String else { return "" }
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
        print("Remote application connected on: \(client.address):\(client.port)")
    }
    func shutdown() {
        print("Disconnecting from \(appDisplayName): \(client.address):\(client.port)")
        client.close()
    }
    func handleReceivedMessage(_ recvMsg: SDLMessage) {
        var response: SDLMessage?
        if recvMsg.frameType == .control {
            response = handleControlMessage(recvMsg)
        } else {
            switch recvMsg.serviceType {
            case .control:
                assert(false, "*** Control services are not handled yet ***")
            case .rpc:
                response = handleRPCMessage(recvMsg)
            case .audio: break
            case .video:
                if let frameData = recvMsg.payload { videoProjection.addFrame(frameData) }
            case .bulkData: break
            }
        }
        if let respMsg = response {
            sendMessageID += 1
            respMsg.messageID = sendMessageID
            respMsg.send(client: client)
        }
    }
    func receiveMessages() {
        DispatchQueue.global(qos: .default).async {
            while (true) {
                guard let msg = SDLMessage.read(self.client) else { continue } // Wait here for incoming msg
                print("===================================================================")
                print("Recv \(msg.description)")
                switch msg.frameType {
                case .control,.single:
                    self.handleReceivedMessage(msg)
                case .first:
                    assert(false, "*** 'First' frames are not handled yet ***")
                case .consecutive:
                    assert(false, "*** 'Consecutive' frames are not handled yet ***")
                }
            }
        }
    }
}

//
// Control Message Handlers
//
extension RemoteApplication {
    func handleStartService(_ request: SDLMessage) -> SDLMessage? {
        if (request.serviceType == .video) {
            NotificationCenter.default.post(name: .videoSessionOpened, object: nil, userInfo: nil)
        }
        let response = request.createResponseHeader()
        response.setPayload(Data([0x11, 0x22, 0x33, 0x44])) // hash of the service which was started on the head unit
        return response
    }
    func handleEndService(_ request: SDLMessage) -> SDLMessage? {
        if (request.serviceType == .video) {
            NotificationCenter.default.post(name: .videoSessionClosed, object: nil, userInfo: nil)
        }
        let response = request.createResponseHeader()
        return response
    }
    func handleHeartbeat(_ request: SDLMessage) -> SDLMessage? {
        let response = request.createResponseHeader()
        return response
    }
    func handleControlMessage(_ request: SDLMessage) -> SDLMessage? {
        var response: SDLMessage?
        switch request.controlCmd {
        case .heartbeat:
            response = handleHeartbeat(request)
        case .startService:
            response = handleStartService(request)
        case .endService:
            guard let immediate = handleEndService(request) else { return nil }
            sendMessageID += 1
            immediate.messageID = sendMessageID
            immediate.send(client: client) // Special case
            RemoteApplicationManager.sharedInstance.remove(self)
            break
        default: assert(false, "*** Unhandled Control Command \(request.controlCmd) ***")
        }
        return response
    }
}

//
// RPC Message Handlers
//
extension RemoteApplication {
    func sendHMIStatus(audible: Bool) {
        let notification = SDLMessage.init(compressed: false,
                                       frameType: .single,
                                       serviceType: .rpc,
                                       controlCmd: .heartbeat,
                                       sessionID: 0,
                                       functionID: .onHMIStatus,
                                       correlationID: 0)
        isAudible = audible
        notification.rpcType = .notification
        do {
            var responseParams = Dictionary<String, Any>()
            responseParams["audioStreamingState"]   = isAudible ? "AUDIBLE" : "NOT_AUDIBLE"
            responseParams["hmiLevel"]              = "FULL"
            responseParams["systemContext"]         = "MAIN"
            if let jsonData = try responseParams.jsonData() {
                notification.setJSON(jsonData)
            }
        } catch let error as NSError { print(error) }
        notification.send(client: client)
    }
    func sendTouchEvent(type: SDLTouchType, id: Int, timestamp: Int, point: NSPoint) {
        let notification = SDLMessage.init(compressed: false,
                                           frameType: .single,
                                           serviceType: .rpc,
                                           controlCmd: .heartbeat,
                                           sessionID: 0,
                                           functionID: .onTouchEvent,
                                           correlationID: 0)
        notification.rpcType = .notification
        do {
            let responseParams = [
                "type": type.rawValue,
                "event": [
                    [
                        "id": id,
                        "ts": timestamp,
                        "c": [
                            [
                                "x": Int(point.x),
                                "y": Int(point.y)
                            ]
                        ]
                    ]
                ]
            ] as [String : Any]
            if let jsonData = try responseParams.jsonData() {
                notification.setJSON(jsonData)
            }
        } catch let error as NSError { print(error) }
        notification.send(client: client)
    }
    func sendButtonEvent(button: SDLButtonName, mode: SDLButtonEventMode) {
        let notification = SDLMessage.init(compressed: false,
                                           frameType: .single,
                                           serviceType: .rpc,
                                           controlCmd: .heartbeat,
                                           sessionID: 0,
                                           functionID: .onTouchEvent,
                                           correlationID: 0)
        notification.rpcType = .notification
        do {
            let responseParams = [
                "name": button.rawValue,
                "mode": mode.rawValue
                ] as [String : Any]
            if let jsonData = try responseParams.jsonData() {
                notification.setJSON(jsonData)
            }
        } catch let error as NSError { print(error) }
        notification.send(client: client)
    }
    func sendButtonPress(button: SDLButtonName, mode: SDLButtonPressMode) {
        let notification = SDLMessage.init(compressed: false,
                                           frameType: .single,
                                           serviceType: .rpc,
                                           controlCmd: .heartbeat,
                                           sessionID: 0,
                                           functionID: .onTouchEvent,
                                           correlationID: 0)
        notification.rpcType = .notification
        do {
            let responseParams = [
                "name": button.rawValue,
                "mode": mode.rawValue
                ] as [String : Any]
            if let jsonData = try responseParams.jsonData() {
                notification.setJSON(jsonData)
            }
        } catch let error as NSError { print(error) }
        notification.send(client: client)
    }
    func handleRegisterAppInterface(_ request: SDLMessage, params: Dictionary<String, Any>?) -> SDLMessage {
        // Parse params
        if let params = params {
            appInterface = params
            print("Name....: \(appDisplayName)")
            print("BundleID: \(appBundleID)")
            print("Version.: \(appVersion)")
            print("Media...: \(isMediaApplication ? "ENABLED" : "DISABLED")")
        }
        // Build response
        let response = request.createResponseHeader();
        do {
            if let json = NSDataAsset.init(name: "RegisterAppInterfaceResponse") { // Use precanned response JSON
                if let precannedRPC = try Dictionary<String, Any>.create(fromJSONData: json.data) {
                    // TODO: Tweak response params here if necessary
                    if let jsonData = try precannedRPC.jsonData() {
                        response.setJSON(jsonData)
                    }
                }
            }
        } catch let error as NSError { print(error) }
        return response
    }
    func handleOnHMIStatus(_ request: SDLMessage, params: Dictionary<String, Any>?) -> SDLMessage {
        let response = request.createResponseHeader();
        //**********
        sendHMIStatus(audible: true) // Temp hack to allow video streaming from app
        //**********
        return response
    }
    func handleHapticData(_ request: SDLMessage, params: Dictionary<String, Any>?) -> SDLMessage {
        let response = request.createResponseHeader();
        return response
    }
    func handleListFiles(_ request: SDLMessage, params: Dictionary<String, Any>?) -> SDLMessage {
        let response = request.createResponseHeader();
        do {
            var responseParams = Dictionary<String, Any>()
            responseParams["success"]        = true
            responseParams["resultCode"]     = "SUCCESS"
            responseParams["spaceAvailable"] = 104857600
            if let jsonData = try responseParams.jsonData() {
                response.setJSON(jsonData)
            }
        } catch let error as NSError { print(error) }
        return response
    }
    func handleRPCMessage(_ msg: SDLMessage) -> SDLMessage? {
        var response: SDLMessage?
        var params: Dictionary<String, Any>?
        do {
            if let dict = try msg.jsonDictionary() {
                params = dict
                //if let str = try dict.jsonString() {
                //    print("\(msg.functionID): \n (\(str))")
                //} else {
                //    print("\(msg.functionID): \n (\(params ?? Dictionary<String, Any>()))")
                //}
            } else {
                assert(false, "*** Failed to decode JSON data into Dictionary ***")
            }
        } catch let error as NSError { print(error.localizedDescription) }
        switch msg.functionID {
        case .registerAppInterface: response = handleRegisterAppInterface(msg, params: params)
        case .onHMIStatus:      response = handleOnHMIStatus(msg, params: params)
        case .listFiles:        response = handleListFiles(msg, params: params)
        case .sendHapticData:       response = handleHapticData(msg, params: params)
        default:                    assert(false, "*** \(msg.functionID) is not implemented ***")
        }
        return response
    }
}
