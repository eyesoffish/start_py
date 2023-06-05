import Cocoa
import FlutterMacOS
//let ShellDir = NSHomeDirectory()+"/Library"
//let updateShellPath = ShellDir+"/openChrome.py"
class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    guard let path = Bundle.main.path(forResource: "openChrome.py", ofType: nil) else {
        print("未找到跟新脚本")
        return
    }
    print(path);
//    if FileManager.default.fileExists(atPath: updateShellPath) {
//        try? FileManager.default.removeItem(atPath: updateShellPath)
//    } else {
//        try? FileManager.default.createDirectory(at: URL(fileURLWithPath: ShellDir), withIntermediateDirectories: true, attributes: nil)
//    }
//    do {
//      try FileManager.default.copyItem(at: URL(fileURLWithPath: path), to: URL(fileURLWithPath: updateShellPath))
//    } catch {
//        print("error = \(error)")
//    }
//    print(updateShellPath)
    
    super.awakeFromNib()
  }
}
