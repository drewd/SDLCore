//
//  ViewController.swift
//  SDLCore
//
//  Created by Michael Pitts on 8/25/17.
//  Copyright © 2017 Xevo. All rights reserved.
//

import Cocoa

private let viewportWidth   = 800
private let viewportHeight  = 480
private let windowWidth     = viewportWidth + 40
private let windowHeight    = viewportHeight + 260

class MaskedButton : NSImageView {
    
    override open func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        
        let target = NSMakeRect(event.locationInWindow.x, event.locationInWindow.y, 1.0, 1.0)

        //Swift.print("HitAt: (\(target.origin.x), \(target.origin.y)) - (\(target.origin.x+target.width), \(target.origin.y+target.height))")
        //Swift.print("Frame: (\(self.frame.origin.x), \(self.frame.origin.y)) - (\(self.frame.origin.x+self.frame.width), \(self.frame.origin.y+self.frame.height))")

        
        guard let hit = self.image?.hitTest(target,
                                      withDestinationRect: self.frame,
                                      context: nil,
                                      hints: nil,
                                      flipped: false) else { return }
        
        if hit {
            if let name = self.image?.name() {
                Swift.print("\(name) pressed")
            }
        }
    }
}


class ViewController: NSViewController {

    @IBOutlet weak var downButton: NSImageView!
    @IBOutlet weak var leftButton: NSImageView!
    @IBOutlet weak var upButton: NSImageView!
    @IBOutlet weak var rightButton: NSImageView!
    @IBOutlet weak var okButton: NSImageView!
    
    @IBAction func downPressed(_ sender: NSImageView) {
        print("DOWN pressed");
    }
    @IBAction func leftPressed(_ sender: NSImageView) {
        print("LEFT pressed");
    }
    @IBAction func upPressed(_ sender: NSImageView) {
        print("UP pressed");
    }
    @IBAction func rightPressed(_ sender: NSImageView) {
        print("RIGHT pressed");
    }
    @IBAction func okPressed(_ sender: NSImageView) {
        print("OK pressed");
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.window?.setFrame(NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight), display: true)
        self.view.layer?.backgroundColor = NSColor.black.cgColor
        
        downButton.image?.setName("down")
        upButton.image?.setName("up")
        leftButton.image?.setName("left")
        rightButton.image?.setName("right")
        okButton.image?.setName("OK")
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

