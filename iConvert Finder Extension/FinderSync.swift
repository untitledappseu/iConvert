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
    private let pngToHeicConverter = PNGtoHEICConverter()
    private let jpgToHeicConverter = JPGtoHEICConverter()
    private let mp4ToMovConverter = MP4toMOVConverter()
    private let mp4ToGifConverter = MP4toGIFConverter()
    private let movToMp4Converter = MOVtoMP4Converter()
    private let aviToMp4Converter = AVItoMP4Converter()
    private let mp4ToWebmConverter = MP4toWebMConverter()

    // Audio converters
    private let mp3ToWavConverter = MP3toWAVConverter()
    private let wavToMp3Converter = WAVtoMP3Converter()
    private let m4aToMp3Converter = M4AtoMP3Converter()
    private let mp3ToM4aConverter = MP3toM4AConverter()
    private let wavToFlacConverter = WAVtoFLACConverter()
    private let flacToWavConverter = FLACtoWAVConverter()

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

        // Also check UTI types for more robust HEIC detection
        let heicUTIs = ["public.heic", "com.apple.heic"]
        let heicFilesUTI = selectedItems.filter {
            if let uti = try? $0.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
                let isHeicUTI = heicUTIs.contains(uti)
                if isHeicUTI && !heicFiles.contains($0) {
                    os_log("Found additional HEIC file by UTI: %{public}@, UTI: %{public}@", log: logger, type: .debug, $0.path, uti)
                    return true
                }
            }
            return false
        }

        // Combine both detection methods
        let allHeicFiles = heicFiles + heicFilesUTI
        os_log("Total HEIC files after UTI check: %d", log: logger, type: .debug, allHeicFiles.count)

        // Filter for WebP files
        let webpFiles = selectedItems.filter { $0.pathExtension.lowercased() == "webp" }

        // Filter for video files
        let mp4Files = selectedItems.filter { $0.pathExtension.lowercased() == "mp4" }
        let movFiles = selectedItems.filter { $0.pathExtension.lowercased() == "mov" }
        let aviFiles = selectedItems.filter { $0.pathExtension.lowercased() == "avi" }

        // Also check UTI types for more robust video detection
        let videoUTIs = ["public.mpeg-4", "com.apple.quicktime-movie", "public.avi"]
        let videoFilesUTI = selectedItems.filter {
            if let uti = try? $0.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
                return videoUTIs.contains(uti) && !mp4Files.contains($0) && !movFiles.contains($0) && !aviFiles.contains($0)
            }
            return false
        }

        // Combine both detection methods
        let allVideoFiles = mp4Files + movFiles + aviFiles + videoFilesUTI
        os_log("Total video files after UTI check: %d", log: logger, type: .debug, allVideoFiles.count)

        // Filter for audio files
        let mp3Files = selectedItems.filter { $0.pathExtension.lowercased() == "mp3" }
        let wavFiles = selectedItems.filter { $0.pathExtension.lowercased() == "wav" }
        let m4aFiles = selectedItems.filter { $0.pathExtension.lowercased() == "m4a" }
        let flacFiles = selectedItems.filter { $0.pathExtension.lowercased() == "flac" }

        // Also check UTI types for more robust audio detection
        let audioUTIs = ["public.mp3", "public.audio", "public.wav", "public.m4a", "org.xiph.flac"]
        let audioFilesUTI = selectedItems.filter {
            if let uti = try? $0.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
                return audioUTIs.contains(uti) && !mp3Files.contains($0) && !wavFiles.contains($0) && !m4aFiles.contains($0) && !flacFiles.contains($0)
            }
            return false
        }

        // Combine both detection methods
        let allAudioFiles = mp3Files + wavFiles + m4aFiles + flacFiles + audioFilesUTI
        os_log("Total audio files after UTI check: %d", log: logger, type: .debug, allAudioFiles.count)

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

            let pngToHeicItem = NSMenuItem(title: "PNG to HEIC", action: #selector(convertPNGtoHEIC), keyEquivalent: "")
            pngToHeicItem.target = self
            submenu.addItem(pngToHeicItem)
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

            let jpgToHeicItem = NSMenuItem(title: "JPG to HEIC", action: #selector(convertJPGtoHEIC), keyEquivalent: "")
            jpgToHeicItem.target = self
            submenu.addItem(jpgToHeicItem)

            os_log("Added JPG to WebP menu item", log: logger, type: .debug)
        } else {
            os_log("No JPG files found, skipping JPG conversion options", log: logger, type: .debug)
        }

        // Add HEIC conversion options
        if !allHeicFiles.isEmpty {
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

        // Add video conversion options
        if !allVideoFiles.isEmpty {
            // Add a separator if we have other conversion options
            if !submenu.items.isEmpty {
                submenu.addItem(NSMenuItem.separator())
            }

            // MP4 specific options
            if !mp4Files.isEmpty {
                let mp4ToMovItem = NSMenuItem(title: "MP4 to MOV", action: #selector(convertMP4toMOV), keyEquivalent: "")
                mp4ToMovItem.target = self
                submenu.addItem(mp4ToMovItem)

                let mp4ToGifItem = NSMenuItem(title: "MP4 to GIF", action: #selector(convertMP4toGIF), keyEquivalent: "")
                mp4ToGifItem.target = self
                submenu.addItem(mp4ToGifItem)

                let mp4ToWebmItem = NSMenuItem(title: "MP4 to WebM", action: #selector(convertMP4toWebM), keyEquivalent: "")
                mp4ToWebmItem.target = self
                submenu.addItem(mp4ToWebmItem)
            }

            // MOV specific options
            if !movFiles.isEmpty {
                let movToMp4Item = NSMenuItem(title: "MOV to MP4", action: #selector(convertMOVtoMP4), keyEquivalent: "")
                movToMp4Item.target = self
                submenu.addItem(movToMp4Item)
            }

            // AVI specific options
            if !aviFiles.isEmpty {
                let aviToMp4Item = NSMenuItem(title: "AVI to MP4", action: #selector(convertAVItoMP4), keyEquivalent: "")
                aviToMp4Item.target = self
                submenu.addItem(aviToMp4Item)
            }
        }

        // Add audio conversion options
        if !allAudioFiles.isEmpty {
            // Add a separator if we have other conversion options
            if !submenu.items.isEmpty {
                submenu.addItem(NSMenuItem.separator())
            }

            // MP3 specific options
            if !mp3Files.isEmpty {
                let mp3ToWavItem = NSMenuItem(title: "MP3 to WAV", action: #selector(convertMP3toWAV), keyEquivalent: "")
                mp3ToWavItem.target = self
                submenu.addItem(mp3ToWavItem)

                let mp3ToM4aItem = NSMenuItem(title: "MP3 to M4A", action: #selector(convertMP3toM4A), keyEquivalent: "")
                mp3ToM4aItem.target = self
                submenu.addItem(mp3ToM4aItem)
            }

            // WAV specific options
            if !wavFiles.isEmpty {
                let wavToMp3Item = NSMenuItem(title: "WAV to MP3", action: #selector(convertWAVtoMP3), keyEquivalent: "")
                wavToMp3Item.target = self
                submenu.addItem(wavToMp3Item)

                let wavToFlacItem = NSMenuItem(title: "WAV to FLAC", action: #selector(convertWAVtoFLAC), keyEquivalent: "")
                wavToFlacItem.target = self
                submenu.addItem(wavToFlacItem)
            }

            // M4A specific options
            if !m4aFiles.isEmpty {
                let m4aToMp3Item = NSMenuItem(title: "M4A to MP3", action: #selector(convertM4AtoMP3), keyEquivalent: "")
                m4aToMp3Item.target = self
                submenu.addItem(m4aToMp3Item)
            }

            // FLAC specific options
            if !flacFiles.isEmpty {
                let flacToWavItem = NSMenuItem(title: "FLAC to WAV", action: #selector(convertFLACtoWAV), keyEquivalent: "")
                flacToWavItem.target = self
                submenu.addItem(flacToWavItem)
            }
        }

        // Only return menu if we have conversion options
        if submenu.items.isEmpty {
            return nil
        }

        let convertItem = NSMenuItem(title: "iConvert", action: nil, keyEquivalent: "")
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

        // Filter for HEIC files using both extension and UTI
        let heicFiles = selectedItems.filter { $0.pathExtension.lowercased() == "heic" }

        let heicUTIs = ["public.heic", "com.apple.heic"]
        let heicFilesUTI = selectedItems.filter {
            if let uti = try? $0.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
                let isHeicUTI = heicUTIs.contains(uti)
                if isHeicUTI && !heicFiles.contains($0) {
                    os_log("Found additional HEIC file by UTI: %{public}@, UTI: %{public}@", log: logger, type: .debug, $0.path, uti)
                    return true
                }
            }
            return false
        }

        let allHeicFiles = heicFiles + heicFilesUTI
        os_log("Converting %d HEIC files", log: logger, type: .info, allHeicFiles.count)

        for fileURL in allHeicFiles {
            let success = heicToJpgConverter.convert(fileURL)
            os_log("Conversion %{public}@", log: logger, type: .info, success ? "succeeded" : "failed")
        }
    }

    @objc func convertHEICtoPNG() {
        os_log("convertHEICtoPNG() called", log: logger, type: .debug)

        guard let selectedItems = FIFinderSyncController.default().selectedItemURLs() else {
            return
        }

        // Filter for HEIC files using both extension and UTI
        let heicFiles = selectedItems.filter { $0.pathExtension.lowercased() == "heic" }

        let heicUTIs = ["public.heic", "com.apple.heic"]
        let heicFilesUTI = selectedItems.filter {
            if let uti = try? $0.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
                let isHeicUTI = heicUTIs.contains(uti)
                if isHeicUTI && !heicFiles.contains($0) {
                    os_log("Found additional HEIC file by UTI: %{public}@, UTI: %{public}@", log: logger, type: .debug, $0.path, uti)
                    return true
                }
            }
            return false
        }

        let allHeicFiles = heicFiles + heicFilesUTI
        os_log("Converting %d HEIC files", log: logger, type: .info, allHeicFiles.count)

        for fileURL in allHeicFiles {
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

        // Filter for HEIC files using both extension and UTI
        let heicFiles = selectedItems.filter { $0.pathExtension.lowercased() == "heic" }

        let heicUTIs = ["public.heic", "com.apple.heic"]
        let heicFilesUTI = selectedItems.filter {
            if let uti = try? $0.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
                return heicUTIs.contains(uti) && !heicFiles.contains($0)
            }
            return false
        }

        let allHeicFiles = heicFiles + heicFilesUTI
        os_log("Converting %d HEIC files", log: logger, type: .info, allHeicFiles.count)

        for fileURL in allHeicFiles {
            let success = heicToWebpConverter.convert(fileURL)
            os_log("Conversion %{public}@", log: logger, type: .info, success ? "succeeded" : "failed")
        }
    }

    @objc func convertMP4toMOV() {
        os_log("convertMP4toMOV() called", log: logger, type: .debug)

        guard let selectedItems = FIFinderSyncController.default().selectedItemURLs() else {
            return
        }

        // Filter for MP4 files
        let mp4Files = selectedItems.filter { $0.pathExtension.lowercased() == "mp4" }
        os_log("Converting %d MP4 files", log: logger, type: .info, mp4Files.count)

        for fileURL in mp4Files {
            mp4ToMovConverter.convert(sourceURL: fileURL)
            os_log("Started conversion of %{public}@", log: logger, type: .info, fileURL.lastPathComponent)
        }
    }

    @objc func convertMP4toGIF() {
        os_log("convertMP4toGIF() called", log: logger, type: .debug)

        guard let selectedItems = FIFinderSyncController.default().selectedItemURLs() else {
            return
        }

        // Filter for MP4 files
        let mp4Files = selectedItems.filter { $0.pathExtension.lowercased() == "mp4" }
        os_log("Converting %d MP4 files", log: logger, type: .info, mp4Files.count)

        for fileURL in mp4Files {
            mp4ToGifConverter.convert(sourceURL: fileURL)
            os_log("Started conversion of %{public}@", log: logger, type: .info, fileURL.lastPathComponent)
        }
    }

    @objc func convertMP4toWebM() {
        os_log("convertMP4toWebM() called", log: logger, type: .debug)

        guard let selectedItems = FIFinderSyncController.default().selectedItemURLs() else {
            return
        }

        // Filter for MP4 files
        let mp4Files = selectedItems.filter { $0.pathExtension.lowercased() == "mp4" }

        for fileURL in mp4Files {
            mp4ToWebmConverter.convert(sourceURL: fileURL)
        }
    }

    @objc func convertMOVtoMP4() {
        os_log("convertMOVtoMP4() called", log: logger, type: .debug)

        guard let selectedItems = FIFinderSyncController.default().selectedItemURLs() else {
            return
        }

        // Filter for MOV files
        let movFiles = selectedItems.filter { $0.pathExtension.lowercased() == "mov" }
        os_log("Converting %d MOV files", log: logger, type: .info, movFiles.count)

        for fileURL in movFiles {
            movToMp4Converter.convert(sourceURL: fileURL)
            os_log("Started conversion of %{public}@", log: logger, type: .info, fileURL.lastPathComponent)
        }
    }

    @objc func convertAVItoMP4() {
        os_log("convertAVItoMP4() called", log: logger, type: .debug)

        guard let selectedItems = FIFinderSyncController.default().selectedItemURLs() else {
            return
        }

        // Filter for AVI files
        let aviFiles = selectedItems.filter { $0.pathExtension.lowercased() == "avi" }
        os_log("Converting %d AVI files", log: logger, type: .info, aviFiles.count)

        for fileURL in aviFiles {
            aviToMp4Converter.convert(sourceURL: fileURL)
            os_log("Started conversion of %{public}@", log: logger, type: .info, fileURL.lastPathComponent)
        }
    }

    @objc func convertPNGtoHEIC() {
        os_log("convertPNGtoHEIC() called", log: logger, type: .debug)

        guard let selectedItems = FIFinderSyncController.default().selectedItemURLs() else {
            return
        }

        // Filter for PNG files
        let pngFiles = selectedItems.filter { $0.pathExtension.lowercased() == "png" }
        os_log("Converting %d PNG files", log: logger, type: .info, pngFiles.count)

        for fileURL in pngFiles {
            let success = pngToHeicConverter.convert(fileURL)
            os_log("Conversion %{public}@", log: logger, type: .info, success ? "succeeded" : "failed")
        }
    }

    @objc func convertJPGtoHEIC() {
        os_log("convertJPGtoHEIC() called", log: logger, type: .debug)

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

        // Combine both detection methods
        let allJpgFiles = jpgFiles + jpgFilesUTI
        os_log("Converting %d JPG files", log: logger, type: .info, allJpgFiles.count)

        for fileURL in allJpgFiles {
            let success = jpgToHeicConverter.convert(fileURL)
            os_log("Conversion %{public}@", log: logger, type: .info, success ? "succeeded" : "failed")
        }
    }

    // Audio conversion methods
    @objc func convertMP3toWAV() {
        os_log("convertMP3toWAV() called", log: logger, type: .debug)

        guard let selectedItems = FIFinderSyncController.default().selectedItemURLs() else {
            return
        }

        // Filter for MP3 files
        let mp3Files = selectedItems.filter { $0.pathExtension.lowercased() == "mp3" }

        for fileURL in mp3Files {
            let success = mp3ToWavConverter.convert(fileURL)
            os_log("Conversion %{public}@", log: logger, type: .info, success ? "succeeded" : "failed")
        }
    }

    @objc func convertWAVtoMP3() {
        os_log("convertWAVtoMP3() called", log: logger, type: .debug)

        guard let selectedItems = FIFinderSyncController.default().selectedItemURLs() else {
            return
        }

        // Filter for WAV files
        let wavFiles = selectedItems.filter { $0.pathExtension.lowercased() == "wav" }

        for fileURL in wavFiles {
            let success = wavToMp3Converter.convert(fileURL)
            os_log("Conversion %{public}@", log: logger, type: .info, success ? "succeeded" : "failed")
        }
    }

    @objc func convertM4AtoMP3() {
        os_log("convertM4AtoMP3() called", log: logger, type: .debug)

        guard let selectedItems = FIFinderSyncController.default().selectedItemURLs() else {
            return
        }

        // Filter for M4A files
        let m4aFiles = selectedItems.filter { $0.pathExtension.lowercased() == "m4a" }

        for fileURL in m4aFiles {
            let success = m4aToMp3Converter.convert(fileURL)
            os_log("Conversion %{public}@", log: logger, type: .info, success ? "succeeded" : "failed")
        }
    }

    @objc func convertMP3toM4A() {
        os_log("convertMP3toM4A() called", log: logger, type: .debug)

        guard let selectedItems = FIFinderSyncController.default().selectedItemURLs() else {
            return
        }

        // Filter for MP3 files
        let mp3Files = selectedItems.filter { $0.pathExtension.lowercased() == "mp3" }

        for fileURL in mp3Files {
            let success = mp3ToM4aConverter.convert(fileURL)
            os_log("Conversion %{public}@", log: logger, type: .info, success ? "succeeded" : "failed")
        }
    }

    @objc func convertWAVtoFLAC() {
        os_log("convertWAVtoFLAC() called", log: logger, type: .debug)

        guard let selectedItems = FIFinderSyncController.default().selectedItemURLs() else {
            return
        }

        // Filter for WAV files
        let wavFiles = selectedItems.filter { $0.pathExtension.lowercased() == "wav" }

        for fileURL in wavFiles {
            let success = wavToFlacConverter.convert(fileURL)
            os_log("Conversion %{public}@", log: logger, type: .info, success ? "succeeded" : "failed")
        }
    }

    @objc func convertFLACtoWAV() {
        os_log("convertFLACtoWAV() called", log: logger, type: .debug)

        guard let selectedItems = FIFinderSyncController.default().selectedItemURLs() else {
            return
        }

        // Filter for FLAC files
        let flacFiles = selectedItems.filter { $0.pathExtension.lowercased() == "flac" }

        for fileURL in flacFiles {
            let success = flacToWavConverter.convert(fileURL)
            os_log("Conversion %{public}@", log: logger, type: .info, success ? "succeeded" : "failed")
        }
    }
}


