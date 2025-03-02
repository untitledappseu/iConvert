//
//  webptojpg.swift
//  iConvert Finder Extension.
//
//  @JuditKaramazov, 2023.
//

import Cocoa
import os.log
import WebKit

class WebPtoJPGConverter {
    private let logger = OSLog(subsystem: "at.untitledapps.iConvert", category: "WebPtoJPG")

    func convert(_ sourceURL: URL) -> Bool {
        os_log("Converting WebP to JPG: %{public}@", log: logger, type: .info, sourceURL.path)

        // Create destination URL
        let filename = sourceURL.deletingPathExtension().lastPathComponent
        let newFilename = "\(filename).jpg"
        let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(newFilename)

        os_log("Destination file: %{public}@", log: logger, type: .debug, destinationURL.path)

        // Use dwebp command line tool to convert WebP to PNG first
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".png")

        do {
            // Check if dwebp exists
            let fileManager = FileManager.default
            let dwebpPath = "/opt/homebrew/bin/dwebp"
            var executableURL: URL

            if fileManager.fileExists(atPath: dwebpPath) {
                executableURL = URL(fileURLWithPath: dwebpPath)
                os_log("Using dwebp at: %{public}@", log: logger, type: .debug, dwebpPath)
            } else {
                // Try to find dwebp in PATH
                let whichProcess = Process()
                whichProcess.executableURL = URL(fileURLWithPath: "/usr/bin/which")
                whichProcess.arguments = ["dwebp"]

                let outputPipe = Pipe()
                whichProcess.standardOutput = outputPipe

                try whichProcess.run()
                whichProcess.waitUntilExit()

                let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
                    executableURL = URL(fileURLWithPath: path)
                    os_log("Found dwebp at: %{public}@", log: logger, type: .info, path)
                } else {
                    os_log("dwebp not found in PATH. Please install WebP tools", log: logger, type: .error)
                    return false
                }
            }

            // Convert WebP to PNG using dwebp
            let dwebpProcess = Process()
            dwebpProcess.executableURL = executableURL
            dwebpProcess.arguments = [sourceURL.path, "-o", tempURL.path]

            let outputPipe = Pipe()
            dwebpProcess.standardOutput = outputPipe
            dwebpProcess.standardError = outputPipe

            try dwebpProcess.run()
            dwebpProcess.waitUntilExit()

            if dwebpProcess.terminationStatus != 0 {
                let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? "Unknown error"
                os_log("Error converting WebP to PNG: %{public}@", log: logger, type: .error, output)
                return false
            }

            // Load the PNG image
            guard let image = NSImage(contentsOf: tempURL) else {
                os_log("Failed to load temporary PNG image", log: logger, type: .error)
                try? FileManager.default.removeItem(at: tempURL)
                return false
            }

            // Convert to JPG
            guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                os_log("Failed to get CGImage", log: logger, type: .error)
                try? FileManager.default.removeItem(at: tempURL)
                return false
            }

            let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
            guard let jpgData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) else {
                os_log("Failed to convert to JPG data", log: logger, type: .error)
                try? FileManager.default.removeItem(at: tempURL)
                return false
            }

            // Write to file
            try jpgData.write(to: destinationURL)

            // Clean up temporary file
            try FileManager.default.removeItem(at: tempURL)

            os_log("Successfully converted file to: %{public}@", log: logger, type: .info, destinationURL.path)

            // Reveal in Finder
            DispatchQueue.main.async {
                NSWorkspace.shared.activateFileViewerSelecting([destinationURL])
            }
            return true
        } catch {
            os_log("Error in WebP to JPG conversion process: %{public}@", log: logger, type: .error, error.localizedDescription)
            try? FileManager.default.removeItem(at: tempURL)
            return false
        }
    }
}
