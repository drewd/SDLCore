
import Foundation

let ssId     = "SDLNameId"
let ssX      = "SDLNameX"
let ssY      = "SDLNameY"
let ssWidth  = "SDLNameWidth"
let ssHeight = "SDLNameHeight"

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
        self.init(identifier: dict[ssId] as! UInt32,
                  x: dict[ssX] as! CGFloat,
                  y: dict[ssY] as! CGFloat,
                  width: dict[ssWidth] as! CGFloat,
                  height: dict[ssHeight] as! CGFloat)
    }
}

class HapticManager {
    static let sharedInstance = HapticManager() // Singleton
    var spatialStructs = [SDLSpatialStruct]()
    func enumerate(closure: (SDLSpatialStruct) -> Void) {
        for spatialStruct in spatialStructs {
            closure(spatialStruct)
        }
    }
    func setSpatialStructs(_ spatialStructs: [Dictionary<String, Any>]) {
        self.spatialStructs.removeAll()
        for spatialStruct in spatialStructs {
            self.spatialStructs.append(SDLSpatialStruct.init(spatialStruct))
        }
    }
}
