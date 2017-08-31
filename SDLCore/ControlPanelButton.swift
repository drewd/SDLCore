
import Cocoa

private var currentlyPressedButton: ControlPanelButton?

class ControlPanelButton : NSImageView {
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

