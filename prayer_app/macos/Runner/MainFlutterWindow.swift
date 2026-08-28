import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    self.delegate = self
    super.awakeFromNib()
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    // Hide window so menu bar app keeps running smoothly in the background
    self.orderOut(nil)
    return false
  }
}
