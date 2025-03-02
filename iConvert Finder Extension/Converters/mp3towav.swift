//
//  mp3towav.swift
//  iConvert Finder Extension.
//
//  @JuditKaramazov, 2023.
//

import Cocoa
import AVFoundation
import os.log

class MP3toWAVConverter {
    private let logger = OSLog(subsystem: "at.untitledapps.iConvert", category: "MP3toWAV")

    func convert(_ sourceURL: URL) -> Bool {
        os_log("Converting MP3 to WAV: %{public}@", log: logger, type: .info, sourceURL.path)

        // Create destination URL
        let filename = sourceURL.deletingPathExtension().lastPathComponent
        let newFilename = "\(filename).wav"
        let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(newFilename)

        os_log("Destination file: %{public}@", log: logger, type: .debug, destinationURL.path)

        // Create asset from the audio file
        let asset = AVAsset(url: sourceURL)

        // Create export session
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            os_log("Failed to create export session", log: logger, type: .error)
            return false
        }

        // Configure export session
        exportSession.outputURL = destinationURL
        exportSession.outputFileType = .wav

        // Remove existing file if needed
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            do {
                try FileManager.default.removeItem(at: destinationURL)
            } catch {
                os_log("Failed to remove existing file: %{public}@", log: logger, type: .error, error.localizedDescription)
                return false
            }
        }

        // Create a semaphore to wait for export completion
        let semaphore = DispatchSemaphore(value: 0)

        // Start export
        var success = false
        exportSession.exportAsynchronously {
            defer {
                semaphore.signal()
            }

            switch exportSession.status {
            case .completed:
                os_log("Successfully converted file to: %{public}@", log: self.logger, type: .info, destinationURL.path)
                success = true

            case .failed:
                if let error = exportSession.error {
                    os_log("Export failed: %{public}@", log: self.logger, type: .error, error.localizedDescription)
                } else {
                    os_log("Export failed with unknown error", log: self.logger, type: .error)
                }

            case .cancelled:
                os_log("Export cancelled", log: self.logger, type: .error)

            default:
                os_log("Export ended with status: %{public}@", log: self.logger, type: .error, String(describing: exportSession.status))
            }
        }

        // Wait for export to complete
        _ = semaphore.wait(timeout: .distantFuture)

        if success {
            // Reveal in Finder
            DispatchQueue.main.async {
                NSWorkspace.shared.activateFileViewerSelecting([destinationURL])
            }
        }

        return success
    }
}