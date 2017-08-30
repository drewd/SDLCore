
import Cocoa

private let viewportWidth   = 800
private let viewportHeight  = 480
private let windowWidth     = viewportWidth + 40
private let windowHeight    = viewportHeight + 260

private var currentlyPressedButton: MaskedButton?

class MaskedButton : NSImageView {
    var isPressed = false
    var normalName: String?
    var pressedName: String?
    override open func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        let hitArea = NSMakeRect(event.locationInWindow.x, event.locationInWindow.y, 1.0, 1.0)
        guard let hit = self.image?.hitTest(hitArea,
                                            withDestinationRect: self.frame,
                                            context: nil,
                                            hints: nil,
                                            flipped: false) else { return }
        if hit {
            if let name = image?.name() {
                normalName = name
                pressedName = name + "_pressed"
                image = NSImage.init(named: pressedName!)
            }
            currentlyPressedButton = self
            isPressed = true
        }
    }
    override open func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        if let button = currentlyPressedButton {
            currentlyPressedButton = nil
            if let name = button.normalName {
                button.image = NSImage.init(named: name)
            }
            button.isPressed = false
            
            let hitArea = NSMakeRect(event.locationInWindow.x, event.locationInWindow.y, 1.0, 1.0)
            guard let hit = button.image?.hitTest(hitArea,
                                                  withDestinationRect: button.frame,
                                                  context: nil,
                                                  hints: nil,
                                                  flipped: false) else { return }
            if hit {
                guard let action = button.action,
                    let target = button.target else { return }
                _ = target.perform(action, with: button)
            }
        }
    }
}

class ViewController: NSViewController {
    
    let borderWidth: CGFloat = 3.0
    
    @IBOutlet weak var upButton: MaskedButton!
    @IBOutlet weak var downButton: MaskedButton!
    @IBOutlet weak var leftButton: MaskedButton!
    @IBOutlet weak var rightButton: MaskedButton!
    @IBOutlet weak var okButton: MaskedButton!
    @IBOutlet weak var displayView: NSImageView!
    @IBOutlet weak var videoDisplay: NSView!
    
    var phoneButton = NSButton()
    var navButton = NSButton()
    var entertainmentButton = NSButton()
    var climateButton = NSButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.window?.setFrame(NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight), display: true)
        NotificationCenter.default.addObserver(forName: .videoStreamingEnabled,
                                               object: nil, queue: nil,
                                               using: videoStreamingEnabled)
        NotificationCenter.default.addObserver(forName: .videoSessionOpened,
                                               object: nil, queue: nil,
                                               using: videoSessionOpened)
        NotificationCenter.default.addObserver(forName: .videoSessionClosed,
                                               object: nil, queue: nil,
                                               using: videoSessionClosed)
        buildMainDisplay()
    }
    
    override func viewDidAppear() {
        self.view.layer?.backgroundColor = NSColor.darkGray.cgColor // Didn't always work when located in viewDidLoad()
        self.videoDisplay.isHidden = true
        self.videoDisplay.layer?.backgroundColor = NSColor.green.cgColor
    }
    
    private func buildMainDisplay() {
        let displayRect = displayView.frame.insetBy(dx: borderWidth, dy: borderWidth)
        if let btnImage = NSImage.init(named: "phone-statusbar-bg") {
            phoneButton = NSButton.init(image: btnImage, target: self, action: #selector(phoneButtonPressed))
            phoneButton.frame = CGRect.init(x: displayRect.origin.x,
                                            y: displayRect.origin.y + displayRect.size.height - btnImage.size.height,
                                            width: btnImage.size.width,
                                            height: btnImage.size.height)
            phoneButton.isBordered = false
            phoneButton.imagePosition = .imageOnly
            self.view.addSubview(phoneButton)
        }
        if let btnImage = NSImage.init(named: "nav-status-bg") {
            navButton = NSButton.init(image: btnImage, target: self, action: #selector(navButtonPressed))
            navButton.frame = CGRect.init(x: displayRect.origin.x + displayRect.size.width - btnImage.size.width,
                                          y: displayRect.origin.y + displayRect.size.height - btnImage.size.height,
                                          width: btnImage.size.width,
                                          height: btnImage.size.height)
            navButton.isBordered = false
            navButton.imagePosition = .imageOnly
            self.view.addSubview(navButton)
        }
        if let btnImage = NSImage.init(named: "media-status-bg") {
            entertainmentButton = NSButton.init(image: btnImage, target: self, action: #selector(entertainmentButtonPressed))
            entertainmentButton.frame = CGRect.init(x: displayRect.origin.x,
                                                    y: displayRect.origin.y,
                                                    width: btnImage.size.width,
                                                    height: btnImage.size.height)
            entertainmentButton.isBordered = false
            entertainmentButton.imagePosition = .imageOnly
            self.view.addSubview(entertainmentButton)
        }
        if let btnImage = NSImage.init(named: "climate-status-bg") {
            climateButton = NSButton.init(image: btnImage, target: self, action: #selector(climateButtonPressed))
            climateButton.frame = CGRect.init(x: displayRect.origin.x + displayRect.size.width - btnImage.size.width,
                                              y: displayRect.origin.y,
                                              width: btnImage.size.width,
                                              height: btnImage.size.height)
            climateButton.isBordered = false
            climateButton.imagePosition = .imageOnly
            self.view.addSubview(climateButton)
        }
    }
    
    func phoneButtonPressed(_ sender: Any) {
        print("phoneButtonPressed")
    }
    
    func navButtonPressed(_ sender: Any) {
        print("navButtonPressed")
    }
    
    func entertainmentButtonPressed(_ sender: Any) {
        print("entertainmentButtonPressed")
    }
    
    func climateButtonPressed(_ sender: Any) {
        print("climateButtonPressed")
    }
    
    func videoStreamingEnabled(notification: Notification) -> Void {
        guard let userInfo = notification.userInfo else { return }
        guard let video = userInfo["VideoProjectionReceiver"] as? VideoProjectionReceiver else { return }
        DispatchQueue.main.async {
            video.setupVideoLayer(self.videoDisplay)
        }
    }
    
    func videoSessionOpened(notification: Notification) -> Void {
        // Defer until first frame is recv'd so we don't briefly display a blank video view
        //DispatchQueue.main.async {
        //    self.videoDisplay.isHidden = false
        //  self.displayView.isHidden = true
        //}
    }
    
    func videoSessionClosed(notification: Notification) -> Void {
        DispatchQueue.main.async {
            self.videoDisplay.isHidden = true
            //self.displayView.isHidden = false
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

