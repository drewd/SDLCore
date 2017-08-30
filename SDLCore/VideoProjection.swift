
import Foundation
import AVFoundation
import VideoToolbox
import SwiftSocket // See: https://github.com/swiftsocket/SwiftSocket

private let listeningPort: Int32 = 0x5555

extension Notification.Name {
    static let videoFrameReceived    = Notification.Name("videoFrameReceived")
    static let videoSessionClosed    = Notification.Name("videoSessionClosed")
    static let videoSessionOpened    = Notification.Name("videoSessionOpened")
    static let videoStreamingEnabled = Notification.Name("videoStreamingEnabled")
}

class VideoProjectionReceiver {
    var videoDecoder: VideoDecoder = VideoDecoder()
    var videoLayer: AVSampleBufferDisplayLayer = AVSampleBufferDisplayLayer()
    var view: NSView?
    //    private let client: TCPClient
    //    init(client: TCPClient) {
    //        self.client = client
    //        print("New video connection:\(client.address):\(client.port)")
    //    }
    init() {
        // Complete hack :/
        NotificationCenter.default.post(name: .videoStreamingEnabled, object: nil, userInfo: ["VideoProjectionReceiver": self])
    }
    func setupVideoLayer(_ videoView: NSView) {
        // create our AVSampleBufferDisplayLayer and add it to the view
        self.view = videoView
        guard let view = self.view else { return }
        self.videoLayer = AVSampleBufferDisplayLayer()
        self.videoLayer.frame = CGRect(x: 0.0, y: 0.0, width: view.bounds.width, height: view.bounds.height)
        self.videoLayer.bounds = view.bounds
        self.videoLayer.videoGravity = AVLayerVideoGravityResizeAspect
        var timebase: CMTimebase?
        _ = CMTimebaseCreateWithMasterClock( kCFAllocatorDefault, CMClockGetHostTimeClock(), &timebase )
        self.videoLayer.controlTimebase = timebase
        CMTimebaseSetTime(self.videoLayer.controlTimebase!, kCMTimeZero)
        CMTimebaseSetRate(self.videoLayer.controlTimebase!, 1.0);
        view.layer?.addSublayer(self.videoLayer)
        
        NotificationCenter.default.addObserver(forName: .AVSampleBufferDisplayLayerFailedToDecode,
                                               object: nil, queue: nil,
                                               using: self.AVSampleBufferDisplayLayerFailedToDecode)
    }
    func AVSampleBufferDisplayLayerFailedToDecode(notification: Notification) -> Void {
        guard let userInfo = notification.userInfo else { return }
        print("*** ERROR: \(userInfo) \n ********")
        print(" ")
    }
    func addFrame(_ frameData: Data) {
        guard let view = self.view else { return }
        frameData.withUnsafeBytes { (u8Ptr: UnsafePointer<UInt8>) in
            let rawPtr = UnsafeMutablePointer(mutating: u8Ptr)
            videoDecoder.receivedRawVideoFrame(rawPtr, withSize: UInt32(frameData.count), completion: { (sampleBuffer) in
                guard let buffer = sampleBuffer else { return }
                if let error = self.videoLayer.error {
                    print("Video Layer Error: \(error), Status: \(self.videoLayer.status)")
                } else {
                    print("Video Layer Status: \(self.videoLayer.status)")
                }
                // Render on main thread
                DispatchQueue.main.async {
                    if (view.isHidden == true) { // Show video view
                        view.isHidden = false
                    }
                    self.videoLayer.enqueue(buffer)
                    self.videoLayer.setNeedsDisplay()
                }
            })
        }
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
