import Cocoa
import FlutterMacOS
import Sparkle

@main
class AppDelegate: FlutterAppDelegate {
  private let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  func getUpdaterController() -> SPUStandardUpdaterController {
      return updaterController
  }
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    print("======================== applicationDidFinishLaunching start updater ")
    
    // let controller = self.getUpdaterController()
    // controller.startUpdater()
    
    // let flutterViewController = mainFlutterWindow.contentViewController as! FlutterViewController
    // GeneratedPluginRegistrant.register(with: self)

    print("======================== applicationDidFinishLaunching set up the updater controller done")
    
    // Set up the updater
    // controller.checkForUpdates(nil)

    // controller.checkForUpdatesInBackground()

    print("======================== applicationDidFinishLaunching end updater ")
  }
}
