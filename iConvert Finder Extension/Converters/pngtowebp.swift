//
//  pngtowebp.swift
//  iConvert Finder Extension.
//
//  @JuditKaramazov, 2023.
//

import Cocoa
import os.log
import WebKit

class PNGtoWebPConverter {
    private let logger = OSLog(subsystem: "at.untitledapps.iConvert", category: "PNGtoWebP")

    func convert(_ sourceURL: URL) -> Bool {
        os_log("Converting PNG to WebP: %{public}@", log: logger, type: .info, sourceURL.path)

        // Create destination URL
        let filename = sourceURL.deletingPathExtension().lastPathComponent
        let newFilename = "\(filename).webp"
        let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(newFilename)

        os_log("Destination file: %{public}@", log: logger, type: .debug, destinationURL.path)

        // Load the image
        guard let image = NSImage(contentsOf: sourceURL) else {
            os_log("Failed to load image", log: logger, type: .error)
            return false
        }

        // Convert to WebP using a temporary PNG file
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            os_log("Failed to get CGImage", log: logger, type: .error)
            return false
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            os_log("Failed to convert to PNG data", log: logger, type: .error)
            return false
        }

        // Create a temporary file for the PNG
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".png")

        do {
            try pngData.write(to: tempURL)

            // Check if cwebp exists
            let fileManager = FileManager.default
            let cwebpPath = "/opt/homebrew/bin/cwebp"
            var executableURL: URL

            if fileManager.fileExists(atPath: cwebpPath) {
                executableURL = URL(fileURLWithPath: cwebpPath)
                os_log("Using cwebp at: %{public}@", log: logger, type: .debug, cwebpPath)
            } else {
                // Try to find cwebp in PATH
                let whichProcess = Process()
                whichProcess.executableURL = URL(fileURLWithPath: "/usr/bin/which")
                whichProcess.arguments = ["cwebp"]

                let outputPipe = Pipe()
                whichProcess.standardOutput = outputPipe

                try whichProcess.run()
                whichProcess.waitUntilExit()

                let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
                    executableURL = URL(fileURLWithPath: path)
                    os_log("Found cwebp at: %{public}@", log: logger, type: .info, path)
                } else {
                    os_log("cwebp not found in PATH. Please install WebP tools", log: logger, type: .error)
                    return false
                }
            }

            // Use cwebp command line tool to convert PNG to WebP
            let process = Process()
            process.executableURL = executableURL
            process.arguments = ["-q", "80", tempURL.path, "-o", destinationURL.path]

            let outputPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = outputPipe

            try process.run()
            process.waitUntilExit()

            // Clean up temporary file
            try FileManager.default.removeItem(at: tempURL)

            if process.terminationStatus == 0 {
                os_log("Successfully converted file to: %{public}@", log: logger, type: .info, destinationURL.path)

                // Reveal in Finder
                DispatchQueue.main.async {
                    NSWorkspace.shared.activateFileViewerSelecting([destinationURL])
                }
                return true
            } else {
                let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? "Unknown error"
                os_log("Error converting to WebP: %{public}@", log: logger, type: .error, output)
                return false
            }
        } catch {
            os_log("Error in WebP conversion process: %{public}@", log: logger, type: .error, error.localizedDescription)
            return false
        }
    }
}
