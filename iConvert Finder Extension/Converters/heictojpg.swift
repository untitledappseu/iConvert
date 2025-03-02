//
//  heictojpg.swift
//  iConvert Finder Extension.
//
//  @JuditKaramazov, 2023.
//

import Cocoa
import os.log

class HEICtoJPGConverter {
    private let logger = OSLog(subsystem: "at.untitledapps.iConvert", category: "HEICtoJPG")

    func convert(_ sourceURL: URL) -> Bool {
        os_log("Converting HEIC to JPG: %{public}@", log: logger, type: .info, sourceURL.path)

        // Create destination URL
        let filename = sourceURL.deletingPathExtension().lastPathComponent
        let newFilename = "\(filename).jpg"
        let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(newFilename)

        os_log("Destination file: %{public}@", log: logger, type: .debug, destinationURL.path)

        // Load the image
        guard let image = NSImage(contentsOf: sourceURL) else {
            os_log("Failed to load image", log: logger, type: .error)
            return false
        }

        // Convert to JPEG
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            os_log("Failed to get CGImage", log: logger, type: .error)
            return false
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) else {
            os_log("Failed to convert to JPEG data", log: logger, type: .error)
            return false
        }

        // Write to file
        do {
            try jpegData.write(to: destinationURL)
            os_log("Successfully converted file to: %{public}@", log: logger, type: .info, destinationURL.path)

            // Reveal in Finder
            DispatchQueue.main.async {
                NSWorkspace.shared.activateFileViewerSelecting([destinationURL])
            }
            return true
        } catch {
            os_log("Error writing JPEG file: %{public}@", log: logger, type: .error, error.localizedDescription)
            return false
        }
    }
}