
import Cocoa

class ImageViewWithText : NSImageView {
    var text = "---"
    override open func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if let font = NSFont.init(name: "Arial", size: 30) {
            let attrs = [NSFontAttributeName:font,
                         NSForegroundColorAttributeName:NSColor.white]
            let size = text.size(withAttributes: attrs)
            let x = (self.bounds.size.width / 2) - (size.width / 2)
            let y = (self.bounds.size.height / 2) - (size.height / 2)
            let drawRect = self.bounds.offsetBy(dx: x, dy: -y)
            text.draw(in: drawRect, withAttributes: attrs)
        }
    }
}
