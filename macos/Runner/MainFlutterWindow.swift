import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  // 拦截键盘事件，处理 Cmd+W
  override func keyDown(with event: NSEvent) {
    if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "w" {
      self.orderOut(nil)
      NSApp.hide(nil)
    } else {
      super.keyDown(with: event)
    }
  }
}
