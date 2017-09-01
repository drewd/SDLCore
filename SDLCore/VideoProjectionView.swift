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
                for spatialStruct in self.spatialStructs {
                    Swift.print("-- spatialStruct \(spatialStruct)")
                }
                self.setNeedsDisplay(frameRect)
                self.displayIfNeeded()
            })
        }
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        func next() {
            if spatialStructs.count == 0 { return }
            if currentFocusID == 0 {
                currentFocusID = spatialStructs[0].identifier
            } else if let index = spatialStructs.index(where: { $0.identifier == currentFocusID } ) {
                if index + 1 >= spatialStructs.count {
                    currentFocusID = 0
                } else {
                    currentFocusID = spatialStructs[index + 1].identifier
                }
            }
        }
        func prev() {
            if spatialStructs.count == 0 { return }
            if currentFocusID == 0 {
                currentFocusID = spatialStructs.last?.identifier ?? 0
            } else if let index = spatialStructs.index(where: { $0.identifier == currentFocusID } ) {
                if index - 1 < 0 {
                    currentFocusID = 0
                } else {
                    currentFocusID = spatialStructs[index - 1].identifier
                }
            }
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
        func notifySelected() {
            if let spatial = spatialStructs.first(where: { $0.identifier == currentFocusID } ) {
                let point = NSPoint(x: spatial.width / 2 + spatial.x,
                                    y: spatial.height / 2 + spatial.y)
                RemoteApplicationManager.sharedInstance.sendTouchEvent(
                    type: .begin, id: Int(spatial.identifier), timestamp: 1000, point: point)
                RemoteApplicationManager.sharedInstance.sendTouchEvent(
                    type: .end, id: Int(spatial.identifier), timestamp: 1001, point: point)
            }
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
