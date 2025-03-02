//
//  webptopng.swift
//  iConvert Finder Extension.
//
//  @JuditKaramazov, 2023.
//

import Cocoa
import os.log
import WebKit

class WebPtoPNGConverter {
    private let logger = OSLog(subsystem: "at.untitledapps.iConvert", category: "WebPtoPNG")

    func convert(_ sourceURL: URL) -> Bool {
        os_log("Converting WebP to PNG: %{public}@", log: logger, type: .info, sourceURL.path)

        // Create destination URL
        let filename = sourceURL.deletingPathExtension().lastPathComponent
        let newFilename = "\(filename).png"
        let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(newFilename)

        os_log("Destination file: %{public}@", log: logger, type: .debug, destinationURL.path)

        // Use dwebp command line tool to convert WebP to PNG
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

            let process = Process()
            process.executableURL = executableURL
            process.arguments = [sourceURL.path, "-o", destinationURL.path]

            let outputPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = outputPipe

            try process.run()
            process.waitUntilExit()

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
                os_log("Error converting WebP to PNG: %{public}@", log: logger, type: .error, output)
                return false
            }
        } catch {
            os_log("Error in WebP to PNG conversion process: %{public}@", log: logger, type: .error, error.localizedDescription)
            return false
        }
    }
}