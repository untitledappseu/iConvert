//
//  mp4togif.swift
//  iConvert Finder Extension.
//
//  @JuditKaramazov, 2023.
//

import Cocoa
import AVFoundation
import ImageIO
import Foundation
import CoreServices
import os.log
import UserNotifications
import UniformTypeIdentifiers

class MP4toGIFConverter {
    private let logger = OSLog(subsystem: "at.untitledapps.iConvert", category: "MP4toGIFConverter")

    func convert(sourceURL: URL) {
        os_log("Starting MP4 to GIF conversion for %{public}@", log: logger, type: .info, sourceURL.path)

        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [self] granted, error in
            if let error = error {
                os_log("Failed to request notification permission: %{public}@", log: self.logger, type: .error, error.localizedDescription)
            }
        }

        // Create destination URL
        let destinationURL = sourceURL.deletingPathExtension().appendingPathExtension("gif")

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

        // Create an asset from the video
        let asset = AVAsset(url: sourceURL)

        // Get video duration
        let duration = CMTimeGetSeconds(asset.duration)

        // Calculate frame count (10 frames per second)
        let frameRate: Double = 10
        let frameCount = Int(duration * frameRate)

        // Create an image generator
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        // Set up GIF properties
        let frameProperties = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFDelayTime as String: 1.0 / frameRate
            ]
        ]

        let gifProperties = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: 0 // 0 means loop forever
            ]
        ]

        // Create GIF destination
        let gifTypeIdentifier: CFString
        if #available(macOS 12.0, *) {
            gifTypeIdentifier = UTType.gif.identifier as CFString
        } else {
            gifTypeIdentifier = kUTTypeGIF
        }

        guard let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL,
            gifTypeIdentifier, frameCount, nil) else {
            os_log("Failed to create GIF destination", log: logger, type: .error)
            showCompletionNotification(success: false)
            return
        }

        // Set GIF properties
        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)

        // Show initial progress notification
        showProgressNotification(progress: 0)

        // Extract frames and add to GIF
        var framesAdded = 0
        var success = true

        for i in 0..<frameCount {
            // Calculate time for this frame
            let time = CMTime(seconds: Double(i) / frameRate, preferredTimescale: 600)

            do {
                // Generate image for time
                let cgImage = try generator.copyCGImage(at: time, actualTime: nil)

                // Add image to GIF
                CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)

                framesAdded += 1

                // Update progress notification every 10 frames
                if i % 10 == 0 || i == frameCount - 1 {
                    let progress = Double(i + 1) / Double(frameCount)
                    showProgressNotification(progress: progress)
                }
            } catch {
                os_log("Failed to generate frame at time %{public}@: %{public}@", log: logger, type: .error, String(describing: time), error.localizedDescription)
                success = false
            }
        }

        // Finalize GIF
        if !CGImageDestinationFinalize(destination) {
            os_log("Failed to finalize GIF", log: logger, type: .error)
            showCompletionNotification(success: false)
            return
        }

        // Check if we added all frames
        if framesAdded < frameCount {
            os_log("Only added %d of %d frames to GIF", log: logger, type: .error, framesAdded, frameCount)
            success = framesAdded > 0
        }

        os_log("Successfully converted MP4 to GIF at %{public}@", log: logger, type: .info, destinationURL.path)
        showCompletionNotification(success: success)

        // Reveal in Finder
        NSWorkspace.shared.activateFileViewerSelecting([destinationURL])
    }

    private func showProgressNotification(progress: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Converting MP4 to GIF"

        // Format progress as percentage
        let percentage = Int(progress * 100)

        // Create a visual progress bar using better characters for a smoother appearance
        let barLength = 20
        let filledLength = Int(Double(barLength) * progress)
        let bar = String(repeating: "●", count: filledLength) + String(repeating: "○", count: barLength - filledLength)

        content.body = "\(percentage)% complete\n\(bar)"

        // Use the progress as identifier to replace previous notifications
        let request = UNNotificationRequest(identifier: "mp4togif.progress", content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { [self] error in
            if let error = error {
                os_log("Failed to show progress notification: %{public}@", log: self.logger, type: .error, error.localizedDescription)
            }
        }
    }

    private func showCompletionNotification(success: Bool) {
        let content = UNMutableNotificationContent()

        if success {
            content.title = "MP4 to GIF Conversion Complete"
            content.body = "Your GIF file has been created successfully."
        } else {
            content.title = "MP4 to GIF Conversion Failed"
            content.body = "There was an error creating your GIF file."
        }

        let request = UNNotificationRequest(identifier: "mp4togif.completion", content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { [self] error in
            if let error = error {
                os_log("Failed to show completion notification: %{public}@", log: self.logger, type: .error, error.localizedDescription)
            }
        }
    }
}