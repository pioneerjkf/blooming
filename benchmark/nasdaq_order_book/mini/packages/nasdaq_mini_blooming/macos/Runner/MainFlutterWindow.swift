import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    super.awakeFromNib()

    self.isRestorable = false
    self.setFrameAutosaveName("")

    // Explicitly set content size to 1100 x 656 to ensure exact 20px margins on all 4 sides
    let contentSize = NSSize(width: 1100, height: 656)
    self.setContentSize(contentSize)
    self.center()

    DispatchQueue.main.async {
      self.setContentSize(contentSize)
      self.center()
    }

    RegisterGeneratedPlugins(registry: flutterViewController)
  }
}
