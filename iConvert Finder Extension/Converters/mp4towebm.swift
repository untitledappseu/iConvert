//
//  mp4towebm.swift
//  iConvert Finder Extension.
//
//  @JuditKaramazov, 2023.
//

import Cocoa
import AVFoundation
import os.log
import UserNotifications

class MP4toWebMConverter {
    private let logger = OSLog(subsystem: "at.untitledapps.iConvert", category: "MP4toWebMConverter")
    private var progressTimer: Timer?

    func convert(sourceURL: URL) {
        os_log("Starting MP4 to WebM conversion for %{public}@", log: logger, type: .info, sourceURL.lastPathComponent)

        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [self] granted, error in
            if let error = error {
                os_log("Error requesting notification permission: %{public}@", log: self.logger, type: .error, error.localizedDescription)
                return
            }
        }

        // Create destination URL
        let destinationURL = sourceURL.deletingPathExtension().appendingPathExtension("webm")

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

        // For WebM conversion, we need to use FFmpeg as AVFoundation doesn't support WebM directly
        // This implementation uses a shell command to FFmpeg
        // First, check if FFmpeg is installed
        let ffmpegTask = Process()
        ffmpegTask.launchPath = "/usr/bin/which"
        ffmpegTask.arguments = ["ffmpeg"]

        let outputPipe = Pipe()
        ffmpegTask.standardOutput = outputPipe

        do {
            try ffmpegTask.run()
            ffmpegTask.waitUntilExit()

            if ffmpegTask.terminationStatus != 0 {
                os_log("FFmpeg not found. Please install FFmpeg to convert to WebM.", log: logger, type: .error)
                showCompletionNotification(success: false)
                return
            }
        } catch {
            os_log("Error checking for FFmpeg: %{public}@", log: logger, type: .error, error.localizedDescription)
            showCompletionNotification(success: false)
            return
        }

        // Get FFmpeg path
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard let ffmpegPath = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            os_log("Could not determine FFmpeg path", log: logger, type: .error)
            showCompletionNotification(success: false)
            return
        }

        // Set up FFmpeg conversion
        let conversionTask = Process()
        conversionTask.launchPath = ffmpegPath
        conversionTask.arguments = [
            "-i", sourceURL.path,
            "-c:v", "libvpx-vp9",
            "-crf", "30",
            "-b:v", "0",
            "-c:a", "libopus",
            "-y", // Overwrite output file without asking
            destinationURL.path
        ]

        // Start a timer to show indeterminate progress (FFmpeg doesn't provide easy progress tracking)
        var progressCounter = 0
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            progressCounter += 1
            let simulatedProgress = min(Float(progressCounter) / 100.0, 0.95) // Cap at 95% until complete
            self.showProgressNotification(progress: simulatedProgress)
        }

        // Start conversion
        do {
            try conversionTask.run()
            conversionTask.waitUntilExit()

            // Stop the progress timer
            progressTimer?.invalidate()
            progressTimer = nil

            if conversionTask.terminationStatus == 0 {
                os_log("MP4 to WebM conversion completed successfully", log: logger, type: .info)
                showCompletionNotification(success: true)

                // Reveal in Finder
                DispatchQueue.main.async {
                    NSWorkspace.shared.activateFileViewerSelecting([destinationURL])
                }
            } else {
                os_log("FFmpeg conversion failed with status: %d", log: logger, type: .error, conversionTask.terminationStatus)
                showCompletionNotification(success: false)
            }
        } catch {
            // Stop the progress timer
            progressTimer?.invalidate()
            progressTimer = nil

            os_log("Error running FFmpeg: %{public}@", log: logger, type: .error, error.localizedDescription)
            showCompletionNotification(success: false)
        }
    }

    private func showProgressNotification(progress: Float) {
        let content = UNMutableNotificationContent()
        content.title = "Converting MP4 to WebM"

        // Create a visual progress bar
        let percentage = Int(progress * 100)
        let progressBarWidth = 20
        let filledChars = Int(Float(progressBarWidth) * progress)
        let emptyChars = progressBarWidth - filledChars
        let progressBar = String(repeating: "●", count: filledChars) + String(repeating: "○", count: emptyChars)

        content.body = "\(percentage)% complete\n\(progressBar)"
        content.sound = nil

        let request = UNNotificationRequest(identifier: "mp4towebm.progress", content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { [self] error in
            if let error = error {
                os_log("Failed to show progress notification: %{public}@", log: self.logger, type: .error, error.localizedDescription)
            }
        }
    }

    private func showCompletionNotification(success: Bool) {
        let content = UNMutableNotificationContent()

        if success {
            content.title = "MP4 to WebM Conversion Complete"
            content.body = "Your video has been successfully converted to WebM format."
        } else {
            content.title = "MP4 to WebM Conversion Failed"
            content.body = "There was an error converting your video. Please try again."
        }

        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: "mp4towebm.completion", content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { [self] error in
            if let error = error {
                os_log("Failed to show completion notification: %{public}@", log: self.logger, type: .error, error.localizedDescription)
            }
        }
    }
}
