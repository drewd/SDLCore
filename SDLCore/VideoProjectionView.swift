//
//  VideoProjectionView.swift
//  SDLCore
//
//  Created by Drew Dobson on 8/30/17.
//  Copyright © 2017 Xevo. All rights reserved.
//

import Cocoa

class VideoProjectionView: NSView {
    //
    // TODO: Should FocusView get broken up into FocusManager and a separate FocusView???
    //
    class FocusView: NSView {
        var currentFocusID: UInt32 = 0
        var spatialStructs = [SDLSpatialStruct]()
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            HapticManager.sharedInstance.registerForUpdates(regionsUpdated: { (spatialStructs) in
                self.spatialStructs = spatialStructs
            })
            for spatialStruct in self.spatialStructs {
                Swift.print("-- spatialStruct \(spatialStruct)")
            }
        }
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        func next() {
            if spatialStructs.count == 0 { return }
            currentFocusID += 1
            if (currentFocusID >= UInt32(spatialStructs.count)) { currentFocusID = 0 }
        }
        func prev() {
            if spatialStructs.count == 0 { return }
            currentFocusID -= 1
            if (currentFocusID >= UInt32(spatialStructs.count)) { currentFocusID = UInt32(spatialStructs.count - 1) }
            
        }
        func moveLeft() {
            if spatialStructs.count == 0 { return }
            // TODO:
        }
        func moveRight() {
            if spatialStructs.count == 0 { return }
            // TODO:
        }
        func moveUp() {
            if spatialStructs.count == 0 { return }
            // TODO:
        }
        func moveDown() {
            if spatialStructs.count == 0 { return }
            // TODO:
        }
        override func draw(_ dirtyRect: NSRect) {
            super.draw(dirtyRect)
            for spatialStruct in self.spatialStructs {
                let text = String(spatialStruct.identifier)
                let flippedRect = NSRect(x: spatialStruct.x,
                                         y: self.bounds.height - (spatialStruct.y + spatialStruct.height),
                                         width: spatialStruct.width,
                                         height: spatialStruct.height)
                let border = NSBezierPath(roundedRect: flippedRect, xRadius: 2, yRadius: 2)
                if spatialStruct.identifier == currentFocusID {
                    NSColor.yellow.set()
                } else {
                    NSColor.purple.set()
                }
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
    
    var focusView = FocusView()
    
    override open func viewDidUnhide() {
        super.viewDidUnhide()
        focusView = FocusView(frame: NSRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height))
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
