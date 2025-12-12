import Foundation
import CoreGraphics

@_silgen_name("DisplayServicesSetBrightness")
func DisplayServicesSetBrightness(_ display: CGDirectDisplayID, _ brightness: Float) -> Int32

func main() {
    guard CommandLine.arguments.count > 1,
          let brightnessPercent = Float(CommandLine.arguments[1]),
          brightnessPercent >= 0 && brightnessPercent <= 100 else {
        print("Usage: apple-brightness <0-100>")
        exit(1)
    }
    
    let brightness = brightnessPercent / 100.0
    
    var displayCount: UInt32 = 0
    CGGetActiveDisplayList(0, nil, &displayCount)
    
    let displays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: Int(displayCount))
    defer { displays.deallocate() }
    CGGetActiveDisplayList(displayCount, displays, &displayCount)
    
    for i in 0..<Int(displayCount) {
        let displayID = displays[i]
        _ = DisplayServicesSetBrightness(displayID, brightness)
    }
}

main()
