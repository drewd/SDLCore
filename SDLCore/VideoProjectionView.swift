//
//  VideoProjectionView.swift
//  SDLCore
//
//  Created by Drew Dobson on 8/30/17.
//  Copyright © 2017 Xevo. All rights reserved.
//

import Cocoa

class VideoProjectionView: NSView {

    override func mouseDown(with event: NSEvent) {
        sendTouch(type: .begin, event: event)
    }
    override func mouseUp(with event: NSEvent) {
        sendTouch(type: .end, event: event)
    }
    override func mouseDragged(with event: NSEvent) {
        sendTouch(type: .move, event: event)
    }
    
    private func sendTouch(type: SDLTouchType, event: NSEvent) {
        var point = self.convert(event.locationInWindow, from: nil)
        if point.x > 0 && point.y > 0 {
            // Only send touches that are still inside our window (IE moving off the screen will not send)
            // Since on iOS and Android (0, 0) is top left and MacOS is bottom left,
            // translate the y coordinate so the clients do not have to.
            point.y = self.frame.size.height - point.y
            RemoteApplicationManager.sharedInstance.sendTouchEvent(type: type, id: event.eventNumber, timestamp: Int(event.timestamp), point: point)
        }
    }
}
