//
//  HandsetServer.swift
//  SDLCore
//
//  Created by Michael Pitts on 8/25/17.
//  Copyright © 2017 Xevo. All rights reserved.
//

import Foundation

// See: https://github.com/swiftsocket/SwiftSocket
import SwiftSocket

private let readBufferSize = 16 * 1024

class HandsetServer {
//    var inputStream: InputStream!
//    var outputStream: OutputStream!
    static let sharedInstance = HandsetServer()
    
    func handsetConnected(client: TCPClient) {
        print("New handset:\(client.address)[\(client.port)]")
        DispatchQueue.global(qos: .default).async {
            if let data = client.read(readBufferSize) {
                print("Recv \(data.count) bytes from \(client.address)[\(client.port)]")
                print(" ")
            }
        }
        
        //let d = client.read(1024*10)
        //client.send(data: d!)
        //client.close()
    }
    
    func start() {
        let server = TCPServer(address: "0.0.0.0", port: 12345)
        switch server.listen() {
        case .success:
            while true {
                if let client = server.accept() {
                    handsetConnected(client: client)
                } else {
                    print("accept error")
                }
            }
        case .failure(let error):
            print(error)
        }
    }
}
