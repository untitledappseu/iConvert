//
//  FinderSync.swift
//  iConvert Finder Extension.
//
//  @JuditKaramazov, 2023.
//

import Cocoa
import FinderSync
import os.log

class FinderSync: FIFinderSync {

    // Create a logger that prints to the console
    private let logger = OSLog(subsystem: "at.untitledapps.iConvert", category: "FinderSync")

    // Converters
    private let pngToJpgConverter = PNGtoJPGConverter()
    private let jpgToPngConverter = JPGtoPNGConverter()
    private let heicToJpgConverter = HEICtoJPGConverter()
    private let heicToPngConverter = HEICtoPNGConverter()
    private let pngToWebpConverter = PNGtoWebPConverter()
    private let jpgToWebpConverter = JPGtoWebPConverter()
    private let webpToJpgConverter = WebPtoJPGConverter()
    private let webpToPngConverter = WebPtoPNGConverter()
    private let heicToWebpConverter = HEICtoWebPConverter()

    override init() {
        super.init()

        // Monitor the entire file system
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]

        // Log initialization
        os_log("FinderSync() launched from %{public}@", log: logger, type: .debug, Bundle.main.bundlePath)
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        // Produce a menu for the extension
        os_log("Menu requested for %{public}@", log: logger, type: .debug, menuKind.rawValue.description)

        let selectedItems = FIFinderSyncController.default().selectedItemURLs()
        os_log("Selected items: %{public}@", log: logger, type: .debug, selectedItems?.description ?? "None")

        guard let selectedItems = selectedItems, !selectedItems.isEmpty else {
            return nil
        }

        // Filter for PNG files
        let pngFiles = selectedItems.filter { $0.pathExtension.lowercased() == "png" }

        // Filter for JPG files
        let jpgFiles = selectedItems.filter {
            let ext = $0.pathExtension.lowercased()
            let isJpg = ext == "jpg" || ext == "jpeg"
            if isJpg {
                os_log("Found JPG file: %{public}@", log: logger, type: .debug, $0.path)
            }
            return isJpg
        }
        os_log("Found %d JPG files: %{public}@", log: logger, type: .debug, jpgFiles.count, jpgFiles.description)

        // Also check UTI types for more robust detection
        let jpgUTIs = ["public.jpeg", "public.jpg"]
        let jpgFilesUTI = selectedItems.filter {
            if let uti = try? $0.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
                let isJpgUTI = jpgUTIs.contains(uti)
                if isJpgUTI && !jpgFiles.contains($0) {
                    os_log("Found additional JPG file by UTI: %{public}@, UTI: %{public}@", log: logger, type: .debug, $0.path, uti)
                    return true
                }
            }
            return false
        }

        // Combine both detection methods
        let allJpgFiles = jpgFiles + jpgFilesUTI
        os_log("Total JPG files after UTI check: %d", log: logger, type: .debug, allJpgFiles.count)

        // Filter for HEIC files
        let heicFiles = selectedItems.filter { $0.pathExtension.lowercased() == "heic" }

        // Filter for WebP files
        let webpFiles = selectedItems.filter { $0.pathExtension.lowercased() == "webp" }

        // Create menu
        let menu = NSMenu(title: "iConvert")
        let submenu = NSMenu(title: "Convert")

        // Add PNG conversion options
        if !pngFiles.isEmpty {
            let pngToJpgItem = NSMenuItem(title: "PNG to JPG", action: #selector(convertPNGtoJPG), keyEquivalent: "")
            pngToJpgItem.target = self
            submenu.addItem(pngToJpgItem)

            let pngToWebpItem = NSMenuItem(title: "PNG to WebP", action: #selector(convertPNGtoWebP), keyEquivalent: "")
            pngToWebpItem.target = self
            submenu.addItem(pngToWebpItem)
        }

        // Add JPG conversion options
        if !allJpgFiles.isEmpty {
            os_log("Adding JPG conversion options to menu", log: logger, type: .debug)

            let jpgToPngItem = NSMenuItem(title: "JPG to PNG", action: #selector(convertJPGtoPNG), keyEquivalent: "")
            jpgToPngItem.target = self
            submenu.addItem(jpgToPngItem)

            let jpgToWebpItem = NSMenuItem(title: "JPG to WebP", action: #selector(convertJPGtoWebP), keyEquivalent: "")
            jpgToWebpItem.target = self
            submenu.addItem(jpgToWebpItem)

            os_log("Added JPG to WebP menu item", log: logger, type: .debug)
        } else {
            os_log("No JPG files found, skipping JPG conversion options", log: logger, type: .debug)
        }

        // Add HEIC conversion options
        if !heicFiles.isEmpty {
            let heicToJpgItem = NSMenuItem(title: "HEIC to JPG", action: #selector(convertHEICtoJPG), keyEquivalent: "")
            heicToJpgItem.target = self
            submenu.addItem(heicToJpgItem)

            let heicToPngItem = NSMenuItem(title: "HEIC to PNG", action: #selector(convertHEICtoPNG), keyEquivalent: "")
            heicToPngItem.target = self
            submenu.addItem(heicToPngItem)

            let heicToWebpItem = NSMenuItem(title: "HEIC to WebP", action: #selector(convertHEICtoWebP), keyEquivalent: "")
            heicToWebpItem.target = self
            submenu.addItem(heicToWebpItem)
        }

        // Add WebP conversion options
        if !webpFiles.isEmpty {
            let webpToJpgItem = NSMenuItem(title: "WebP to JPG", action: #selector(convertWebPtoJPG), keyEquivalent: "")
            webpToJpgItem.target = self
            submenu.addItem(webpToJpgItem)

            let webpToPngItem = NSMenuItem(title: "WebP to PNG", action: #selector(convertWebPtoPNG), keyEquivalent: "")
            webpToPngItem.target = self
            submenu.addItem(webpToPngItem)
        }

        // Only return menu if we have conversion options
        if submenu.items.isEmpty {
            return nil
        }

        let convertItem = NSMenuItem(title: "Convert", action: nil, keyEquivalent: "")
        menu.addItem(convertItem)
        menu.setSubmenu(submenu, for: convertItem)

        return menu
    }

    @objc func convertPNGtoJPG() {
        os_log("convertPNGtoJPG() called", log: logger, type: .debug)

        guard let selectedItems = FIFinderSyncController.default().selectedItemURLs() else {
            return
        }

        // Filter for PNG files
        let pngFiles = selectedItems.filter { $0.pathExtension.lowercased() == "png" }
        os_log("Converting %d PNG files", log: logger, type: .info, pngFiles.count)

        for fileURL in pngFiles {
            let success = pngToJpgConverter.convert(fileURL)
            os_log("Conversion %{public}@", log: logger, type: .info, success ? "succeeded" : "failed")
        }
    }

    @objc func convertJPGtoPNG() {
        os_log("convertJPGtoPNG() called", log: logger, type: .debug)

        guard let selectedItems = FIFinderSyncController.default().selectedItemURLs() else {
            return
        }

        // Filter for JPG files using both extension and UTI
        let jpgFiles = selectedItems.filter {
            let ext = $0.pathExtension.lowercased()
            let isJpg = ext == "jpg" || ext == "jpeg"
            return isJpg
        }

        let jpgUTIs = ["public.jpeg", "public.jpg"]
        let jpgFilesUTI = selectedItems.filter {
            if let uti = try? $0.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
                return jpgUTIs.contains(uti) && !jpgFiles.contains($0)
            }
            return false
        }

        let allJpgFiles = jpgFiles + jpgFilesUTI
        os_log("Converting %d JPG files", log: logger, type: .info, allJpgFiles.count)

        for fileURL in allJpgFiles {
            let success = jpgToPngConverter.convert(fileURL)
            os_log("Conversion %{public}@", log: logger, type: .info, success ? "succeeded" : "failed")
        }
    }

    @objc func convertHEICtoJPG() {
        os_log("convertHEICtoJPG() called", log: logger, type: .debug)

        guard let selectedItems = FIFinderSyncController.default().selectedItemURLs() else {
            return
        }

        // Filter for HEIC files
        let heicFiles = selectedItems.filter { $0.pathExtension.lowercased() == "heic" }
        os_log("Converting %d HEIC files", log: logger, type: .info, heicFiles.count)

        for fileURL in heicFiles {
            let success = heicToJpgConverter.convert(fileURL)
            os_log("Conversion %{public}@", log: logger, type: .info, success ? "succeeded" : "failed")
        }
    }

    @objc func convertHEICtoPNG() {
        os_log("convertHEICtoPNG() called", log: logger, type: .debug)

        guard let selectedItems = FIFinderSyncController.default().selectedItemURLs() else {
            return
        }

        // Filter for HEIC files
        let heicFiles = selectedItems.filter { $0.pathExtension.lowercased() == "heic" }
        os_log("Converting %d HEIC files", log: logger, type: .info, heicFiles.count)

        for fileURL in heicFiles {
            let success = heicToPngConverter.convert(fileURL)
            os_log("Conversion %{public}@", log: logger, type: .info, success ? "succeeded" : "failed")
        }
    }

    @objc func convertPNGtoWebP() {
        os_log("convertPNGtoWebP() called", log: logger, type: .debug)

        guard let selectedItems = FIFinderSyncController.default().selectedItemURLs() else {
            return
        }

        // Filter for PNG files
        let pngFiles = selectedItems.filter { $0.pathExtension.lowercased() == "png" }
        os_log("Converting %d PNG files", log: logger, type: .info, pngFiles.count)

        for fileURL in pngFiles {
            let success = pngToWebpConverter.convert(fileURL)
            os_log("Conversion %{public}@", log: logger, type: .info, success ? "succeeded" : "failed")
        }
    }

    @objc func convertJPGtoWebP() {
        os_log("convertJPGtoWebP() called", log: logger, type: .debug)

        guard let selectedItems = FIFinderSyncController.default().selectedItemURLs() else {
            return
        }

        // Filter for JPG files using both extension and UTI
        let jpgFiles = selectedItems.filter {
            let ext = $0.pathExtension.lowercased()
            let isJpg = ext == "jpg" || ext == "jpeg"
            return isJpg
        }

        let jpgUTIs = ["public.jpeg", "public.jpg"]
        let jpgFilesUTI = selectedItems.filter {
            if let uti = try? $0.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
                return jpgUTIs.contains(uti) && !jpgFiles.contains($0)
            }
            return false
        }

        let allJpgFiles = jpgFiles + jpgFilesUTI
        os_log("Converting %d JPG files", log: logger, type: .info, allJpgFiles.count)

        for fileURL in allJpgFiles {
            let success = jpgToWebpConverter.convert(fileURL)
            os_log("Conversion %{public}@", log: logger, type: .info, success ? "succeeded" : "failed")
        }
    }

    @objc func convertWebPtoJPG() {
        os_log("convertWebPtoJPG() called", log: logger, type: .debug)

        guard let selectedItems = FIFinderSyncController.default().selectedItemURLs() else {
            return
        }

        // Filter for WebP files
        let webpFiles = selectedItems.filter { $0.pathExtension.lowercased() == "webp" }
        os_log("Converting %d WebP files", log: logger, type: .info, webpFiles.count)

        for fileURL in webpFiles {
            let success = webpToJpgConverter.convert(fileURL)
            os_log("Conversion %{public}@", log: logger, type: .info, success ? "succeeded" : "failed")
        }
    }

    @objc func convertWebPtoPNG() {
        os_log("convertWebPtoPNG() called", log: logger, type: .debug)

        guard let selectedItems = FIFinderSyncController.default().selectedItemURLs() else {
            return
        }

        // Filter for WebP files
        let webpFiles = selectedItems.filter { $0.pathExtension.lowercased() == "webp" }
        os_log("Converting %d WebP files", log: logger, type: .info, webpFiles.count)

        for fileURL in webpFiles {
            let success = webpToPngConverter.convert(fileURL)
            os_log("Conversion %{public}@", log: logger, type: .info, success ? "succeeded" : "failed")
        }
    }

    @objc func convertHEICtoWebP() {
        os_log("convertHEICtoWebP() called", log: logger, type: .debug)

        guard let selectedItems = FIFinderSyncController.default().selectedItemURLs() else {
            return
        }

        // Filter for HEIC files
        let heicFiles = selectedItems.filter { $0.pathExtension.lowercased() == "heic" }
        os_log("Converting %d HEIC files", log: logger, type: .info, heicFiles.count)

        for fileURL in heicFiles {
            let success = heicToWebpConverter.convert(fileURL)
            os_log("Conversion %{public}@", log: logger, type: .info, success ? "succeeded" : "failed")
        }
    }
}


