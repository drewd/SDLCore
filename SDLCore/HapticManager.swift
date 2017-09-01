
import Foundation

let ssId     = "id"
let ssRect   = "rect"
let ssX      = "x"
let ssY      = "y"
let ssWidth  = "width"
let ssHeight = "height"

struct SDLSpatialStruct {
    var identifier: UInt32!
    var x: CGFloat!
    var y: CGFloat!
    var width: CGFloat!
    var height: CGFloat!
    init(identifier: UInt32,
         x: CGFloat,
         y: CGFloat,
         width: CGFloat,
         height: CGFloat) {
        self.identifier = identifier
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
    init(_ dict: Dictionary<String, Any>) {
        if let rect = dict[ssRect] as! Dictionary<String, Any>? {
        self.init(identifier: dict[ssId] as! UInt32,
                  x: rect[ssX] as! CGFloat,
                  y: rect[ssY] as! CGFloat,
                  width: rect[ssWidth] as! CGFloat,
                  height: rect[ssHeight] as! CGFloat)
        } else {
            self.init(identifier: dict[ssId] as! UInt32,
                      x: 0,
                      y: 0,
                      width: 0,
                      height: 0)
        }
    }
}

class HapticManager {
    static let sharedInstance = HapticManager() // Singleton
    var regionsUpdated: ([SDLSpatialStruct]) -> Void = {_ in }
    var spatialStructs = [SDLSpatialStruct]()
    func enumerate(closure: (SDLSpatialStruct) -> Void) {
        for spatialStruct in spatialStructs {
            closure(spatialStruct)
        }
    }
    func setSpatialStructs(_ spatialStructs: [Dictionary<String, Any>]) {
        self.spatialStructs.removeAll()
        for spatialStruct in spatialStructs {
            let ss = SDLSpatialStruct.init(spatialStruct)
            if ss.width > 0 {
                self.spatialStructs.append(ss)
            }
        }
        regionsUpdated(self.spatialStructs)
    }
    func registerForUpdates(regionsUpdated: @escaping ([SDLSpatialStruct]) -> Void) {
        self.regionsUpdated = regionsUpdated
        regionsUpdated(self.spatialStructs)
    }
}
