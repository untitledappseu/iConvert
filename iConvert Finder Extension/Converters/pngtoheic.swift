//
//  pngtoheic.swift
//  iConvert Finder Extension.
//
//  @JuditKaramazov, 2023.
//

import Cocoa
import os.log
import ImageIO
import UniformTypeIdentifiers

class PNGtoHEICConverter {
    private let logger = OSLog(subsystem: "at.untitledapps.iConvert", category: "PNGtoHEIC")

    func convert(_ sourceURL: URL) -> Bool {
        os_log("Converting PNG to HEIC: %{public}@", log: logger, type: .info, sourceURL.path)

        // Create destination URL
        let filename = sourceURL.deletingPathExtension().lastPathComponent
        let newFilename = "\(filename).heic"
        let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(newFilename)

        os_log("Destination file: %{public}@", log: logger, type: .debug, destinationURL.path)

        // Load the image
        guard let image = NSImage(contentsOf: sourceURL) else {
            os_log("Failed to load image", log: logger, type: .error)
            return false
        }

        // Convert to HEIC
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            os_log("Failed to get CGImage", log: logger, type: .error)
            return false
        }

        // Create a destination for the HEIC data
        guard let destination = CGImageDestinationCreateWithURL(
            destinationURL as CFURL,
            UTType.heic.identifier as CFString,
            1,
            nil
        ) else {
            os_log("Failed to create image destination", log: logger, type: .error)
            return false
        }

        // Set compression quality
        let properties = [
            kCGImageDestinationLossyCompressionQuality: 0.8
        ] as CFDictionary

        // Add the image to the destination
        CGImageDestinationAddImage(destination, cgImage, properties)

        // Finalize the destination
        if !CGImageDestinationFinalize(destination) {
            os_log("Failed to write HEIC file", log: logger, type: .error)
            return false
        }

        os_log("Successfully converted file to: %{public}@", log: logger, type: .info, destinationURL.path)

        // Reveal in Finder
        DispatchQueue.main.async {
            NSWorkspace.shared.activateFileViewerSelecting([destinationURL])
        }
        return true
    }
}
