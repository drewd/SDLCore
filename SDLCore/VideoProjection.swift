
import Foundation
import SwiftSocket // See: https://github.com/swiftsocket/SwiftSocket

private let listeningPort: Int32 = 0x5555

extension Notification.Name {
    static let videoFrameReceived  = Notification.Name("videoFrameReceived")
    static let videoSessionClosed  = Notification.Name("videoSessionClosed")
    static let videoSessionOpened  = Notification.Name("videoSessionOpened")
}

class VideoProjectionReceiver {
//    private let client: TCPClient
//    init(client: TCPClient) {
//        self.client = client
//        print("New video connection:\(client.address):\(client.port)")
//    }
    func addFrame(_ frameData: Data) {
        // TODO: Make this real someday maybe
        NotificationCenter.default.post(name: .videoFrameReceived, object: nil, userInfo: ["frameData": frameData])
    }
}

//
// Video should listen on its own socket (UDP/RTP perhaps?)
//
//class VideoProjectionListener {
//    static let sharedInstance = VideoProjectionListener() // Singleton
//    func listen() {
//        DispatchQueue.global(qos: .default).async {
//            let server = TCPServer(address: "0.0.0.0", port: listeningPort)
//            switch server.listen() {
//            case .success:
//                while true {
//                    if let client = server.accept() {
//                        let videoReceiver = VideoProjectionReceiver.init(client: client)
//                        videoReceiver.receiveMessages()
//                    } else {
//                        print("accept error")
//                    }
//                }
//            case .failure(let error):
//                print(error)
//            }
//        }
//    }
//}
