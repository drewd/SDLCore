
import Foundation
import SwiftSocket // See: https://github.com/swiftsocket/SwiftSocket

class HandsetManager {
    static let sharedInstance = HandsetManager() // Singleton
    private var handsets = [HandsetApplication]()
    func listen() {
        DispatchQueue.global(qos: .default).async {
            let server = TCPServer(address: "0.0.0.0", port: 12345)
            switch server.listen() {
            case .success:
                while true {
                    if let client = server.accept() {
                        let handset = HandsetApplication.init(client: client)
                        self.handsets.append(handset)
                        handset.processMessages()
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
