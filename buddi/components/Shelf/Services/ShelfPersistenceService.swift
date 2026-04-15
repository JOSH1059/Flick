//
//  ShelfPersistenceService.swift
//  buddi
//
//

import Foundation
import os

// Access model types
@_exported import struct Foundation.URL


final class ShelfPersistenceService {
    private static let logger = os.Logger(subsystem: "com.josh.flick", category: "ShelfPersistence")

    static let shared = ShelfPersistenceService()

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        let fm = FileManager.default
        let support = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = (support ?? fm.temporaryDirectory).appendingPathComponent("buddi", isDirectory: true).appendingPathComponent("Shelf", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("items.json")
        encoder.outputFormatting = [.prettyPrinted]
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
    }

    func load() -> [ShelfItem] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        
        // Try to decode as array first (normal case)
        if let items = try? decoder.decode([ShelfItem].self, from: data) {
            return items
        }
        
        // If array decoding fails, try to decode individual items
        do {
            // Parse as JSON array to get individual item data
            guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [Any] else {
                Self.logger.warning("Shelf persistence file is not a valid JSON array")
                return []
            }
            
            var validItems: [ShelfItem] = []
            var failedCount = 0
            
            for (index, jsonItem) in jsonArray.enumerated() {
                do {
                    let itemData = try JSONSerialization.data(withJSONObject: jsonItem)
                    let item = try decoder.decode(ShelfItem.self, from: itemData)
                    validItems.append(item)
                } catch {
                    failedCount += 1
                    Self.logger.warning("Failed to decode shelf item at index \(index, privacy: .public): \(error.localizedDescription, privacy: .private)")
                }
            }
            
            if failedCount > 0 {
                Self.logger.debug("Successfully loaded \(validItems.count, privacy: .public) shelf items, discarded \(failedCount, privacy: .public) corrupted items")
            }
            
            return validItems
        } catch {
            Self.logger.error("Failed to parse shelf persistence file: \(error.localizedDescription, privacy: .private)")
            return []
        }
    }

    func save(_ items: [ShelfItem]) {
        do {
            let data = try encoder.encode(items)
            try data.write(to: fileURL, options: Data.WritingOptions.atomic)
        } catch {
            Self.logger.error("Failed to save shelf items: \(error.localizedDescription, privacy: .private)")
        }
    }
}
