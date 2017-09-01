//
//  VideoProjectionView.swift
//  SDLCore
//
//  Created by Drew Dobson on 8/30/17.
//  Copyright © 2017 Xevo. All rights reserved.
//

import Cocoa

class VideoProjectionView: NSView {
    
    class FocusView: NSView {
        override func draw(_ dirtyRect: NSRect) {
            super.draw(dirtyRect)
            HapticManager.sharedInstance.enumerate { (spacialStruct) in
                
                Swift.print("-- spacialStruct \(spacialStruct)")
                
                let text = String(spacialStruct.identifier)
                
                let flippedRect = NSRect(x: spacialStruct.x,
                                         y: self.bounds.height - (spacialStruct.y + spacialStruct.height),
                                         width: spacialStruct.width,
                                         height: spacialStruct.height)
                
                let border = NSBezierPath(roundedRect: flippedRect, xRadius: 2, yRadius: 2)
                NSColor.purple.set()
                border.lineWidth = 10
                border.stroke()
                
                if let font = NSFont.init(name: "Arial", size: 18) {
                    let attrs = [NSFontAttributeName:font,
                                 NSForegroundColorAttributeName:NSColor.darkGray]
                    let size = text.size(withAttributes: attrs)
                    let x = (flippedRect.width / 2) - (size.width / 2)
                    let y = (flippedRect.height / 2) - (size.height / 2)
                    let drawRect = flippedRect.offsetBy(dx: x, dy: -y)
                    text.draw(in: drawRect, withAttributes: attrs)
                }
                
            }
        }
    }
    
    var focusView: FocusView?
    
    override open func viewDidUnhide() {
        super.viewDidUnhide()
        self.focusView = FocusView(frame: NSRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height))
        guard let focusView = self.focusView else { return }
        self.addSubview(focusView)
    }
    
    func phoneButtonPressed(_ sender: Any) {
        Swift.print("phoneButtonPressed")
    }
    
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
