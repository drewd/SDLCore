
import Cocoa

private let viewportWidth   = 800
private let viewportHeight  = 480
private let windowWidth     = viewportWidth + 40
private let windowHeight    = viewportHeight + 260

class MaskedButton : NSImageView {
    
    override open func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        let hitArea = NSMakeRect(event.locationInWindow.x, event.locationInWindow.y, 1.0, 1.0)
        guard let hit = self.image?.hitTest(hitArea,
                                      withDestinationRect: self.frame,
                                      context: nil,
                                      hints: nil,
                                      flipped: false) else { return }
        if hit {
            guard let action = self.action,
                let target = self.target else { return }
            _ = target.perform(action, with: self)
        }
    }
}


class ViewController: NSViewController {
    
    @IBOutlet weak var upButton: MaskedButton!
    @IBOutlet weak var downButton: MaskedButton!
    @IBOutlet weak var leftButton: MaskedButton!
    @IBOutlet weak var rightButton: MaskedButton!
    @IBOutlet weak var okButton: MaskedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.window?.setFrame(NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight), display: true)
        self.view.layer?.backgroundColor = NSColor.black.cgColor
        
        NotificationCenter.default.addObserver(forName: .videoFrameReceived,
                                               object: nil, queue: nil,
                                               using: videoFrameReceived)
    }
    
    func videoFrameReceived(notification: Notification) -> Void {
        guard let userInfo = notification.userInfo,
            let frameData  = userInfo["frameData"] as? Data else { return }
        print("Decode H.264: \(frameData.count) bytes")
        // TODO: Decode h.264 data
        DispatchQueue.main.async {
            // Render on main thread
            print("Draw video frame")
        }
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    @IBAction func upPressed(_ sender: Any) {
        print("UP pressed");
    }
    @IBAction func downPressed(_ sender: Any) {
        print("DOWN pressed");
    }
    @IBAction func leftPressed(_ sender: Any) {
        print("LEFT pressed");
    }
    @IBAction func rightPressed(_ sender: Any) {
        print("RIGHT pressed");
    }
    @IBAction func okPressed(_ sender: Any) {
        print("OK pressed");
        RemoteApplicationManager.sharedInstance.activate(); // DEMO HACK to activate the remote app
    }
}

