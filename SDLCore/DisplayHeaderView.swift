
import Cocoa

class DisplayHeaderView : ImageViewWithText {
    var timer = Timer() // For updating the wall time
    public convenience init(image: NSImage) {
        self.init()
        self.image = image
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: { (timer) in
            self.updateWallTimeAndTemp()
        })
    }
    override func viewDidMoveToSuperview() {
        updateWallTimeAndTemp()
    }
    func updateWallTimeAndTemp() {
        let temp = "86º"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm "
        self.text = dateFormatter.string(from: Date.init()) + temp
        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }
    }
}
