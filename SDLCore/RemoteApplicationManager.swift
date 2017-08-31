
import Foundation
import SwiftSocket // See: https://github.com/swiftsocket/SwiftSocket

private let listeningPort: Int32 = 12345

class RemoteApplicationManager {
    static let sharedInstance = RemoteApplicationManager() // Singleton
    private var apps = [RemoteApplication]()
    func listen() {
        DispatchQueue.global(qos: .default).async {
            let server = TCPServer(address: "0.0.0.0", port: listeningPort)
            switch server.listen() {
            case .success:
                while true {
                    if let client = server.accept() {
                        let app = RemoteApplication.init(client: client)
                        self.apps.append(app)
                        app.receiveMessages() // Spawns a thread per connected application (usually one)
                    } else {
                        print("accept error")
                    }
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    func remove(_ app: RemoteApplication) {
        apps = apps.filter { $0.appBundleID != app.appBundleID }
        app.shutdown()
    }
    func sendTouchEvent(type: SDLTouchType, id: Int, timestamp: Int, point: NSPoint) {
        if let app = apps.first {
            app.sendTouchEvent(type: type, id: id, timestamp: timestamp, point: point)
        }
    }
    func sendButtonEvent(button: SDLButtonName, mode: SDLButtonEventMode) {
        if let app = apps.first {
            app.sendButtonEvent(button: button, mode: mode)
        }
    }
    func sendButtonPress(button: SDLButtonName, mode: SDLButtonPressMode) {
        if let app = apps.first {
            app.sendButtonPress(button: button, mode: mode)
        }
    }
}
