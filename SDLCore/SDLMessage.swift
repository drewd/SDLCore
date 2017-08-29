
import Foundation
import SwiftSocket // See: https://github.com/swiftsocket/SwiftSocket


let REPORT_SDL_VERSION: UInt8 = 4

private let V2PROTOCOL_HEADERSIZE = 12
private let maxReadSize = 16 * 1024

enum SDLFrameType: UInt8 {
    case control     = 0x00
    case single      = 0x01
    case first       = 0x02
    case consecutive = 0x03
}

enum SDLServiceType: UInt8 {
    case control    = 0x00
    case rpc        = 0x07
    case audio      = 0x0a
    case video      = 0x0b
    case bulkData   = 0x0f
}

enum SDLControlCommand: UInt8 {
    case heartbeat          = 0x00
    case startService       = 0x01
    case startServiceAck    = 0x02
    case startServiceNack   = 0x03
    case endService         = 0x04
    case endServiceAck      = 0x05
    case endServiceNack     = 0x06
    case serviceDataAck     = 0xfe
    case heartbeatAck       = 0xff
    // If frameType == Single (0x01)
    //case singleFrame        = 0x00
    // If frameType == First (0x02)
    //case firstFrame         = 0x00
    // If frametype == Consecutive (0x03)
    //case consecutiveLastFrame = 0x00
}

enum SDLRPCMessageType: UInt8 {
    case request        = 0
    case response       = 1
    case notification   = 2
};

enum SDLRPCFunctionID: UInt32 {
    case reserved = 0
    case registerAppInterface = 1
    case unregisterAppInterface = 2
    case setGlobalProperties = 3
    case resetGlobalProperties = 4
    case addCommand = 5
    case deleteCommand = 6
    case addSubMenu = 7
    case deleteSubMenu = 8
    case createInteractionChoiceSet = 9
    case performInteraction = 10
    case deleteInteractionChoiceSet = 11
    case alert = 12
    case show = 13
    case speak = 14
    case setMediaClockTimer = 15
    case performAudioPassThru = 16
    case endAudioPassThru = 17
    case subscribeButton = 18
    case unsubscribeButton = 19
    case subscribeVehicleData = 20
    case unsubscribeVehicleData = 21
    case getVehicleData = 22
    case readDID = 23
    case getDTCs = 24
    case scrollableMessage = 25
    case slider = 26
    case showConstantTBT = 27
    case alertManeuver = 28
    case updateTurnList = 29
    case changeRegistration = 30
    case genericResponse = 31
    case putFile = 32
    case deleteFile = 33
    case listFiles = 34
    case setAppIcon = 35
    case setDisplayLayout = 36
    case diagnosticMessage = 37
    case systemRequest = 38
    case sendLocation = 39
    case dialNumber = 40
    case getWaypoints = 45
    case subscribeWaypoints = 46
    case unsubscribeWaypoints = 47
    case sendHapticData = 49 // MAP:
    case onHMIStatus = 32768
    case onAppInterfaceUnregistered = 32769
    case onButtonEvent = 32770
    case onButtonPress = 32771
    case onVehicleData = 32772
    case onCommand = 32773
    case onTBTClientState = 32774
    case onDriverDistraction = 32775
    case onPermissionsChange = 32776
    case onAudioPassThru = 32777
    case onLanguageChange = 32778
    case onKeyboardInput = 32779
    case onTouchEvent = 32780
    case onSystemRequest = 32781
    case onHashChange = 32782
    case onWaypointChange = 32784
    case encodedSyncPData = 65536
    case syncPData = 65537
    case onEncodedSyncPData = 98304
    case onSyncPData = 98305
}

class SDLMessage {
    var version: Byte
    var compressed: Bool
    var frameType: SDLFrameType
    var serviceType: SDLServiceType
    var controlCmd: SDLControlCommand
    var sessionID: Byte
    var rpcType: SDLRPCMessageType = .request
    var functionID: SDLRPCFunctionID = .reserved
    var correlationID: UInt32 = 0
    var bytesInPayload: UInt32 = 0
    var payload: Data?
    var messageID: UInt32 = 0
    var jsonData: Data?
    var jsonLength: UInt32 = 0
    var description: String {
        var desc =
            "version:\(version), " +
                "compressed:\(compressed), " +
                "frameType:\(frameType), " +
                "serviceType:\(serviceType), " +
                "controlCmd:\(controlCmd), " +
        "sessionID:\(sessionID)"
        if version > 1 {
            desc.append(", msgID: \(messageID)")
        }
        if let payload = payload {
            do {
                if frameType != .control && serviceType == .rpc {
                    desc.append(", rpcType: \(rpcType), functionID: \(functionID), correlationID: \(correlationID), jsonLen: \(jsonLength)")
                    if let jsonData = jsonData {
                        if let str = try jsonData.jsonString() {
                            desc.append(str + "\n")
                        } else {
                            desc.append("\nRPC PAYLOAD: \(payload)")
                        }
                    }
                } else {
                    desc.append("\nPAYLOAD: \(payload)")
                }
            } catch let error as NSError { print(error.localizedDescription) }
            
        }
        return desc
    }
    var header: [Byte] {
        var data = Data.init(count: 4)
        data[0] = (version << 4) | ((compressed ? 1 : 0) << 3) | (frameType.rawValue & 0x07)
        data[1] = serviceType.rawValue
        data[2] = controlCmd.rawValue
        data[3] = sessionID
        data.append(Data.from(uint32: bytesInPayload))
        if version > 1 {
            data.append(Data.from(uint32: messageID))
        }
        return Array(data);
    }
    init(rawMsg: [Byte]) {
        version     = rawMsg[0] >> 4
        compressed  = (rawMsg[0] & 0x08) == 0x08 ? true : false
        let value: UInt8 = (rawMsg[0] & 0x07)
        frameType   = SDLFrameType(rawValue: value)!
        serviceType = SDLServiceType(rawValue: rawMsg[1])!
        controlCmd   = SDLControlCommand(rawValue: rawMsg[2])!
        sessionID   = rawMsg[3]
        bytesInPayload = CFSwapInt32(UInt32.create(fromData: Array(arrayLiteral: rawMsg[4], rawMsg[5], rawMsg[6], rawMsg[7])))
        //print("bytesInPayload: \(bytesInPayload)")
        if version > 1 {
            messageID = CFSwapInt32(UInt32.create(fromData: Array(arrayLiteral: rawMsg[8], rawMsg[9], rawMsg[10], rawMsg[11])))
            //print("messageID.....: \(messageID)")
        }
    }
    init(compressed: Bool,
         frameType: SDLFrameType,
         serviceType: SDLServiceType,
         controlCmd: SDLControlCommand,
         sessionID: UInt8) {
        self.version     = 1
        self.compressed  = compressed
        self.frameType   = frameType
        self.serviceType = serviceType
        self.controlCmd   = controlCmd
        self.sessionID   = sessionID
    }
    init(compressed: Bool,
         frameType: SDLFrameType,
         serviceType: SDLServiceType,
         controlCmd: SDLControlCommand,
         sessionID: UInt8,
         functionID: SDLRPCFunctionID,
         correlationID: UInt32) {
        self.version        = REPORT_SDL_VERSION
        self.compressed     = compressed
        self.frameType      = frameType
        self.serviceType    = serviceType
        self.controlCmd      = controlCmd
        self.sessionID      = sessionID
        self.functionID     = functionID
        self.correlationID  = correlationID
    }
    func createResponseHeader() -> SDLMessage {
        let response = SDLMessage.init(compressed: compressed,
                                       frameType: frameType,
                                       serviceType: serviceType,
                                       controlCmd: controlCmd,
                                       sessionID: sessionID,
                                       functionID: functionID,
                                       correlationID: correlationID)
        if frameType == .control {
            switch controlCmd {
            case .startService:
                response.controlCmd = .startServiceAck
            case .heartbeat:
                response.controlCmd = .heartbeatAck
            case .endService:
                response.controlCmd = .endServiceAck
            default: assert(false, "*** Response for \(controlCmd) is not implemented ***")
            }
        } else {
            switch serviceType {
            case .rpc:
                response.rpcType = .response
            default: assert(false, "*** Response for \(serviceType) is not implemented ***")
            }
        }
        return response
    }
    func setJSON(_ data: Data) {
        guard serviceType == .rpc else { return }
        guard bytesInPayload == 0 else { return }
        jsonData = data
        jsonLength = UInt32(data.count)
    }
    func setPayload(_ data: Data) {
        guard jsonLength == 0 else { return }
        payload = data
        bytesInPayload = UInt32(data.count)
        switch serviceType {
        case .audio: break
        case .bulkData: break
        case .control: break
        case .rpc:
            if let data = payload {
                if data.count >= 12 {
                    // Parse functionID, correlationID and jsonLength
                    var val: UInt32 = CFSwapInt32(UInt32.create(fromData: Array(arrayLiteral: data[0], data[1], data[2], data[3])))
                    let type = UInt8(val >> 28)
                    val = (val & 0x0fffffff)
                    rpcType         = SDLRPCMessageType(rawValue: type)!
                    functionID      = SDLRPCFunctionID(rawValue: val)!
                    correlationID   = CFSwapInt32(UInt32.create(fromData: Array(arrayLiteral: data[4], data[5], data[6], data[7])))
                    jsonLength      = CFSwapInt32(UInt32.create(fromData: Array(arrayLiteral: data[8], data[9], data[10], data[11])))
                    if jsonLength > 0 {
                        jsonData = Data(data.dropFirst(12))
                    }
                }
            }
        case .video: break
        }
    }
    func jsonDictionary() throws -> Dictionary<String, Any>? {
        guard let jsonData = jsonData else { return nil }
        return try Dictionary<String, Any>.create(fromJSONData: jsonData)
    }
    static func read(_ client: TCPClient) -> SDLMessage? {
        var msg: SDLMessage?
        guard let firstByte = client.read(1) else { return msg }
        let version = firstByte[0] >> 4
        if version < 1 || version > 4 { return msg } // sanity check version
        let remaining = version > 1 ? 11 : 7
        guard let remainingHeaderBytes = client.read(remaining) else { return msg }
        let data = firstByte + remainingHeaderBytes
        //print("Recv'd Header \(data.count) bytes from \(client.address):\(client.port)")
        msg = SDLMessage.init(rawMsg: data)
        guard let safeMsg = msg else { return msg }
        if safeMsg.bytesInPayload > 0 {
            guard let payload = client.read(Int(safeMsg.bytesInPayload)) else { return msg } // Read payload
            //print("Recv'd Payload \(payload.count) bytes")
            safeMsg.setPayload(Data.init(payload))
        }
        return msg
    }
    func send(client: TCPClient) {
        if serviceType == .rpc && payload == nil {
            var val = Data.from(uint32: functionID.rawValue)
            val[0] = (val[0] & 0x0f) | ((rpcType.rawValue) << 4) // Set SDLRPCMessageType
            var p = Data()
            p.append(val) // RPC Type and FunctionID
            p.append(Data.from(uint32: correlationID))
            p.append(Data.from(uint32: jsonLength))
            if let json = jsonData {
                if json.count > 0 {
                    p.append(contentsOf: json)
                }
            }
            payload = p
            bytesInPayload = UInt32(p.count)
        }
        let result = client.send(data: header)
        assert(result.isSuccess, "Failed to send Header \(header.count) bytes: \(result)")
        if bytesInPayload > 0 {
            guard let payload = payload else { return }
            let result = client.send(data: payload)
            assert(result.isSuccess, "Failed to send Payload \(payload.count) bytes: \(result)")
        }
        print("===================================================================")
        print("Sent \(self.description)")
    }
}
