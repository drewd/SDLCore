
import Foundation
import SwiftSocket // See: https://github.com/swiftsocket/SwiftSocket

private let maxReadSize = 16 * 1024

private let V1PROTOCOL_HEADERSIZE = 8

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

enum SDLFrameInfo: UInt8 {
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

class SDLMessage {
    let version: Byte
    let compressed: Bool
    let frameType: SDLFrameType
    let serviceType: SDLServiceType
    let frameInfo: SDLFrameInfo
    let sessionID: Byte
    var bytesInPayload: UInt32 = 0
    var payload: Data?
    var description: String {
        var desc =
            "version:\(version), " +
                "compressed:\(compressed), " +
                "frameType:\(frameType), " +
                "serviceType:\(serviceType), " +
                "frameInfo:\(frameInfo), " +
        "sessionID:\(sessionID)\n"
        if let payload = payload {
            let str = String(data: payload, encoding: String.Encoding.utf8) ?? ""
            desc.append(str)
        }
        return desc
    }
    var header: [Byte] {
        let payloadLength = CFSwapInt32(bytesInPayload)
        return [ (version << 4) | ((compressed ? 1 : 0) << 3) | (frameType.rawValue & 0x07),
                 serviceType.rawValue, frameInfo.rawValue, sessionID,
                 Byte((payloadLength >> 24) & 0xff),
                 Byte((payloadLength >> 16) & 0xff),
                 Byte((payloadLength >> 8)  & 0xff),
                 Byte(payloadLength & 0xff) ]
    }
    init(rawMsg: [Byte]) {
        version     = rawMsg[0] >> 4
        compressed  = (rawMsg[0] & 0x08) == 0x08 ? true : false
        let value: UInt8 = (rawMsg[0] & 0x07)
        frameType   = SDLFrameType(rawValue: value)!
        serviceType = SDLServiceType(rawValue: rawMsg[1])!
        frameInfo   = SDLFrameInfo(rawValue: rawMsg[2])!
        sessionID   = rawMsg[3]
        let payloadLength = (UInt32(rawMsg[4]) << 24) |
            (UInt32(rawMsg[5]) << 16) |
            (UInt32(rawMsg[6]) << 8) |
            UInt32(rawMsg[7])
        bytesInPayload = CFSwapInt32(payloadLength)
    }
    init(version: UInt8,
         compressed: Bool,
         frameType: SDLFrameType,
         serviceType: SDLServiceType,
         frameInfo: SDLFrameInfo,
         sessionID: UInt8) {
        self.version     = version
        self.compressed  = compressed
        self.frameType   = frameType
        self.serviceType = serviceType
        self.frameInfo   = frameInfo
        self.sessionID   = sessionID
    }
    func setPayload(_ data: Data) {
        payload = data
        bytesInPayload = UInt32(data.count)
    }
    func dictionary() throws -> Dictionary<String, Any>? {
        guard let payload = payload else { return nil }
        return try Dictionary<String, Any>.create(fromJSONData: payload)
    }
    static func read(_ client: TCPClient) -> SDLMessage? {
        var msg: SDLMessage?
        guard let data = client.read(V1PROTOCOL_HEADERSIZE) else { return msg } // Read header
        print("Header \(data.count) bytes from \(client.address):\(client.port)")
        if (data.count >= 8) {
            msg = SDLMessage.init(rawMsg: data)
            guard let safeMsg = msg else { return msg }
            if safeMsg.bytesInPayload > 0 {
                guard let payload = client.read(maxReadSize) else { return msg } // Read payload
                print("Payload \(payload.count)")
                safeMsg.setPayload(Data.init(payload))
            }
        }
        if (msg != nil) {
            print("Recv from \(client.address):\(client.port):\n\(msg!.description)")
        }
        print(" ")
        return msg
    }
    func send(client: TCPClient) {
        let result = client.send(data: header)
        print("Sent \(header): \(result)")
        if bytesInPayload > 0 {
            guard let payload = payload else { return }
            let result = client.send(data: payload)
            print("Payload[\(payload.count)] \(payload): \(result)")
        }
    }
}
