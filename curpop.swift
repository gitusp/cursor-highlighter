import Cocoa
import QuartzCore

func parseHexColor(_ hex: String) -> NSColor? {
    var s = hex
    if s.hasPrefix("#") { s.removeFirst() }
    guard let value = UInt64(s, radix: 16) else { return nil }
    let r, g, b, a: CGFloat
    switch s.count {
    case 6:
        r = CGFloat((value >> 16) & 0xFF) / 255
        g = CGFloat((value >> 8) & 0xFF) / 255
        b = CGFloat(value & 0xFF) / 255
        a = 1
    case 8:
        r = CGFloat((value >> 24) & 0xFF) / 255
        g = CGFloat((value >> 16) & 0xFF) / 255
        b = CGFloat((value >> 8) & 0xFF) / 255
        a = CGFloat(value & 0xFF) / 255
    default:
        return nil
    }
    return NSColor(red: r, green: g, blue: b, alpha: a)
}

func printHelp() {
    let progName = (CommandLine.arguments.first as NSString?)?.lastPathComponent ?? "curpop"
    print("""
    Usage: \(progName) [options]

    Draws a comic-style focus burst at the current cursor position.

    Options:
      --scale <number>     Scale factor (default: 1.0). Scales canvas size,
                           inner radius, line width, and inner jitter together.
      --color <hex>        Accent color in #RRGGBB or #RRGGBBAA (default: #000000).
      --duration <seconds> Total duration of the burst in seconds (default: 1.0).
      -h, --help           Show this help and exit.
    """)
}

var scale: CGFloat = 1.0
var accentColor = NSColor.black
var duration: TimeInterval = 1.0

var argIter = CommandLine.arguments.dropFirst().makeIterator()
while let arg = argIter.next() {
    switch arg {
    case "-h", "--help":
        printHelp()
        exit(0)
    case "--scale":
        if let v = argIter.next(), let n = Double(v), n > 0 { scale = CGFloat(n) }
    case "--color":
        if let v = argIter.next(), let c = parseHexColor(v) { accentColor = c }
    case "--duration":
        if let v = argIter.next(), let n = Double(v), n > 0 { duration = n }
    default:
        break
    }
}

let canvasSize: CGFloat = 560 * scale
let lineCount = 512
let innerRadius: CGFloat = 44 * scale
let lineBaseWidth: CGFloat = 2 * scale
let frameInterval: TimeInterval = 0.12
let frameCount = max(1, Int((duration / frameInterval).rounded()))

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let pos = NSEvent.mouseLocation

let window = NSWindow(
    contentRect: NSRect(
        x: pos.x - canvasSize / 2,
        y: pos.y - canvasSize / 2,
        width: canvasSize,
        height: canvasSize
    ),
    styleMask: .borderless,
    backing: .buffered,
    defer: false
)
window.isOpaque = false
window.backgroundColor = .clear
window.level = .screenSaver
window.ignoresMouseEvents = true
window.hasShadow = false
window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

let view = NSView(frame: NSRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
view.wantsLayer = true

let centerPoint = CGPoint(x: canvasSize / 2, y: canvasSize / 2)
let outerRadius = canvasSize / 2

let lineLayer = CAShapeLayer()
lineLayer.frame = view.bounds
lineLayer.fillColor = accentColor.cgColor
lineLayer.strokeColor = NSColor.clear.cgColor
lineLayer.fillRule = .nonZero
view.layer?.addSublayer(lineLayer)

func appendFocusLine(to path: CGMutablePath, angle: CGFloat) {
    let lengthRatio = CGFloat.random(in: 0.78...1.0)
    let innerJitter = CGFloat.random(in: 0...(64 * scale))
    let widthRatio = CGFloat.random(in: 0.55...1.25)
    let midBias = CGFloat.random(in: 0.4...0.6)

    let actualInner = innerRadius + innerJitter
    let actualOuter = outerRadius * lengthRatio
    let halfWidth = (lineBaseWidth * widthRatio) / 2

    let cosA = cos(angle)
    let sinA = sin(angle)
    let perpX = -sinA
    let perpY = cosA
    let mid = actualInner + (actualOuter - actualInner) * midBias

    let innerPoint = CGPoint(
        x: centerPoint.x + cosA * actualInner,
        y: centerPoint.y + sinA * actualInner
    )
    let outerPoint = CGPoint(
        x: centerPoint.x + cosA * actualOuter,
        y: centerPoint.y + sinA * actualOuter
    )
    let midCenter = CGPoint(
        x: centerPoint.x + cosA * mid,
        y: centerPoint.y + sinA * mid
    )
    let midLeft = CGPoint(
        x: midCenter.x + perpX * halfWidth,
        y: midCenter.y + perpY * halfWidth
    )
    let midRight = CGPoint(
        x: midCenter.x - perpX * halfWidth,
        y: midCenter.y - perpY * halfWidth
    )

    path.move(to: innerPoint)
    path.addLine(to: midLeft)
    path.addLine(to: outerPoint)
    path.addLine(to: midRight)
    path.closeSubpath()
}

func drawFrame() {
    let path = CGMutablePath()
    let angleStep = .pi * 2 / CGFloat(lineCount)
    for i in 0..<lineCount {
        let baseAngle = CGFloat(i) * angleStep
        let jitter = CGFloat.random(in: -angleStep...angleStep) * 0.6
        appendFocusLine(to: path, angle: baseAngle + jitter)
    }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    lineLayer.path = path
    CATransaction.commit()
}

window.contentView = view
window.orderFrontRegardless()

drawFrame()
var currentFrame = 1
let timer = Timer.scheduledTimer(withTimeInterval: frameInterval, repeats: true) { t in
    drawFrame()
    currentFrame += 1
    if currentFrame >= frameCount {
        t.invalidate()
        exit(0)
    }
}
RunLoop.main.add(timer, forMode: .common)

app.run()
