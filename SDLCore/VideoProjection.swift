
import Foundation
import SwiftSocket // See: https://github.com/swiftsocket/SwiftSocket

private let listeningPort: Int32 = 0x5555

class VideoProjectionReceiver {
    private let client: TCPClient
    init(client: TCPClient) {
        self.client = client
        print("New video connection:\(client.address):\(client.port)")
    }
    func receiveMessages() {
//        DispatchQueue.global(qos: .default).async {
//            while (true) {
//                guard let data = SDLMessage.read(self.client) else { continue } // Wait here for incoming data
//            }
//        }
    }
}

class VideoProjectionListener {
    static let sharedInstance = VideoProjectionListener() // Singleton
    func listen() {
        DispatchQueue.global(qos: .default).async {
            let server = TCPServer(address: "0.0.0.0", port: listeningPort)
            switch server.listen() {
            case .success:
                while true {
                    if let client = server.accept() {
                        let videoReceiver = VideoProjectionReceiver.init(client: client)
                        videoReceiver.receiveMessages()
                    } else {
                        print("accept error")
                    }
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}
