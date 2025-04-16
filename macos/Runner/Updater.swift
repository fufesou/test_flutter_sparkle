// https://github.com/ZzzM/CalendarX/blob/a0d26cf917aecda954a7b6174d2a7648c1c5e43a/CalendarX/Utility/Updater.swift

import Sparkle

class Updater: NSObject {

    private lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: false,
        updaterDelegate: self,
        userDriverDelegate: nil
    )

    var automaticallyChecksForUpdates: Bool {
        get {
            updaterController.updater.automaticallyChecksForUpdates
        }
        set {
            updaterController.updater.automaticallyChecksForUpdates = newValue
        }
    }

    override
    init() {
        super.init()
        updaterController.startUpdater()
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}

extension Updater: SPUUpdaterDelegate {
    func updaterWillRelaunchApplication(_ updater: SPUUpdater) {
        // Handle relaunch if needed
        print("==================== Relaunching application...")
        
    }

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        // Handle valid update found
        print("==================== Found valid update: \(item)")
    }

    func updater(_ updater: SPUUpdater, didFailToFindUpdate error: Error) {
        // Handle update failure
        print("==================== Failed to find update: \(error)")
    }
    func updater(_ updater: SPUUpdater, didFindInvalidUpdate item: SUAppcastItem) {
        // Handle invalid update found
        print("==================== Found invalid update: \(item)")
    }
    func updater(_ updater: SPUUpdater, didFindUpdate item: SUAppcastItem) {
        // Handle update found
        print("==================== Found update: \(item)")
    }
    func updater(_ updater: SPUUpdater, didFailToUpdate error: Error) {
        // Handle update failure
        print("==================== Failed to update: \(error)")
    }
    func updater(_ updater: SPUUpdater, didUpdate item: SUAppcastItem) {
        // Handle update completed
        print("==================== Update completed: \(item)")
    }
    func updater(_ updater: SPUUpdater, didFailToUpdate item: SUAppcastItem, error: Error) {
        // Handle update failure
        print("==================== Failed to update: \(item), error: \(error)")
    }
    func updater(_ updater: SPUUpdater, didCancelUpdate item: SUAppcastItem) {
        // Handle update cancellation
        print("==================== Update cancelled: \(item)")
    }
    func updater(_ updater: SPUUpdater, didUpdate item: SUAppcastItem, error: Error) {
        // Handle update completed with error
        print("==================== Update completed with error: \(item), error: \(error)")
    }

    // func updater(_ updater: SPUUpdater, 
    //             shouldAllowUnsignedUpdatesForItem item: SUAppcastItem) -> Bool {
    //     print("==================== Checking if unsigned updates are allowed...")
    //     return true
    // }

    func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
        print("==================== Preparing for installation...")
        if #available(macOS 10.15, *) {
            Task {
                do {
                    try await stopRunningServices()
                    try await terminateAllRustDeskProcesses()
                } catch {
                    NSLog("[RustDesk] Pre-installation preparation failed: \(error)")
                }
            }
        } else {
            NSLog("[RustDesk] Task is not supported on macOS versions earlier than 10.15")
        }
    }
    
    func updater(_ updater: SPUUpdater, didFinishInstallationWithResult result: Error?) {
        print("==================== Installation finished with result: \(String(describing: result))")
        if #available(macOS 10.15, *) {
            Task {
                do {
                    try await startServices()
                    NSLog("[RustDesk] Services started successfully")
                } catch {
                    NSLog("[RustDesk] Failed to start services: \(error)")
                }
            }
        } else {
            NSLog("[RustDesk] Task is not supported on macOS versions earlier than 10.15")
        }
    }

    private func stopRunningServices() async throws {
        print("==================== Stopping running services...")
        let commands = [
            "launchctl unload /Library/LaunchDaemons/com.carriez.RustDesk_service.plist",
            "launchctl unload /Library/LaunchAgents/com.carriez.RustDesk_server.plist"
        ]
        
        for cmd in commands {
            try await runShellCommand(cmd)
        }
    }
    
    private func startServices() async throws {
        print("==================== Starting services...")
        let commands = [
            "launchctl load -w /Library/LaunchDaemons/com.carriez.RustDesk_service.plist",
            "launchctl load -w /Library/LaunchAgents/com.carriez.RustDesk_server.plist"
        ]
        
        for cmd in commands {
            try await runShellCommand(cmd)
        }
    }
    
    // MARK: - Process management
    
    private func terminateAllRustDeskProcesses() async throws {
        print("==================== Terminating all RustDesk processes...")
        let pgrep = try await runShellCommand("pgrep -f RustDesk")
        let pids = pgrep.components(separatedBy: .whitespacesAndNewlines)
            .compactMap { Int($0) }
        
        for pid in pids {
            try await runShellCommand("kill -9 \(pid)")
        }
    }
    
    // MARK: - Installer customization
    
    func updater(_ updater: SPUUpdater, installationParametersFor item: SUAppcastItem) -> [String] {
        print("==================== Customizing installation parameters...")
        return [
            "--cleanup",
            "--target", "/Applications/RustDesk.app"
        ]
    }
    
    // MARK: - Utility methods
    
    @discardableResult
    private func runShellCommand(_ command: String) async throws -> String {
        print("==================== Running shell command: \(command)")
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            throw InstallationError.commandFailed(command: command)
        }
        
        guard process.terminationStatus == 0 else {
            throw InstallationError.commandFailed(command: "\(command) (exit: \(process.terminationStatus))")
        }
        
        return output
    }

    // func runPrivilegedCommand(_ command: String) async throws {
    //     var error: NSDictionary?
    //     appleScript?.executeAndReturnError(&error)
        
    //     if let error = error {
    //         throw InstallationError.appleScriptError(details: error)
    //     }
    //     var error: NSDictionary?
    //     appleScript?.executeAndReturnError(&error)
        
    //     if let error = error {
    //         throw error
    //     }
    // }
    
    enum InstallationError: Error {
        case commandFailed(command: String)
        case serviceControlFailed
        case appleScriptError(details: NSDictionary)
    }
}
