//
//  mp4tomov.swift
//  iConvert Finder Extension.
//
//  @JuditKaramazov, 2023.
//

import Cocoa
import AVFoundation
import os.log
import UserNotifications

class MP4toMOVConverter {
    private let logger = OSLog(subsystem: "at.untitledapps.iConvert", category: "MP4toMOVConverter")
    private var progressTimer: Timer?

    func convert(sourceURL: URL) {
        os_log("Starting MP4 to MOV conversion for %{public}@", log: logger, type: .info, sourceURL.lastPathComponent)

        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [self] granted, error in
            if let error = error {
                os_log("Error requesting notification permission: %{public}@", log: self.logger, type: .error, error.localizedDescription)
                return
            }
        }

        // Create destination URL
        let destinationURL = sourceURL.deletingPathExtension().appendingPathExtension("mov")

        // Check if destination file already exists and remove it if necessary
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            do {
                try FileManager.default.removeItem(at: destinationURL)
                os_log("Removed existing file at %{public}@", log: logger, type: .debug, destinationURL.path)
            } catch {
                os_log("Failed to remove existing file: %{public}@", log: logger, type: .error, error.localizedDescription)
                showCompletionNotification(success: false)
                return
            }
        }

        // Create AVAsset from source URL
        let asset = AVAsset(url: sourceURL)

        // Create export session
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            os_log("Failed to create export session", log: logger, type: .error)
            showCompletionNotification(success: false)
            return
        }

        exportSession.outputURL = destinationURL
        exportSession.outputFileType = .mov
        exportSession.shouldOptimizeForNetworkUse = true

        // Start a timer to update progress notification
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.showProgressNotification(progress: exportSession.progress)
        }

        // Start export
        exportSession.exportAsynchronously {
            // Stop the progress timer
            self.progressTimer?.invalidate()
            self.progressTimer = nil

            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    os_log("MP4 to MOV conversion completed successfully", log: self.logger, type: .info)
                    self.showCompletionNotification(success: true)

                    // Reveal in Finder
                    NSWorkspace.shared.activateFileViewerSelecting([destinationURL])

                default:
                    if let error = exportSession.error {
                        os_log("Export failed with error: %{public}@", log: self.logger, type: .error, error.localizedDescription)
                    } else {
                        os_log("Export failed with status: %d", log: self.logger, type: .error, exportSession.status.rawValue)
                    }
                    self.showCompletionNotification(success: false)
                }
            }
        }
    }

    private func showProgressNotification(progress: Float) {
        let content = UNMutableNotificationContent()
        content.title = "Converting MP4 to MOV"

        // Create a visual progress bar
        let percentage = Int(progress * 100)
        let progressBarWidth = 20
        let filledChars = Int(Float(progressBarWidth) * progress)
        let emptyChars = progressBarWidth - filledChars
        let progressBar = String(repeating: "●", count: filledChars) + String(repeating: "○", count: emptyChars)

        content.body = "\(percentage)% complete\n\(progressBar)"
        content.sound = nil

        let request = UNNotificationRequest(identifier: "mp4tomov.progress", content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { [self] error in
            if let error = error {
                os_log("Failed to show progress notification: %{public}@", log: self.logger, type: .error, error.localizedDescription)
            }
        }
    }

    private func showCompletionNotification(success: Bool) {
        let content = UNMutableNotificationContent()

        if success {
            content.title = "MP4 to MOV Conversion Complete"
            content.body = "Your video has been successfully converted to MOV format."
        } else {
            content.title = "MP4 to MOV Conversion Failed"
            content.body = "There was an error converting your video. Please try again."
        }

        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: "mp4tomov.completion", content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { [self] error in
            if let error = error {
                os_log("Failed to show completion notification: %{public}@", log: self.logger, type: .error, error.localizedDescription)
            }
        }
    }
}