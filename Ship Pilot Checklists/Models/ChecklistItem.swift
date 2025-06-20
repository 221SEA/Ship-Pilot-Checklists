//
//  ChecklistItem.swift
//  Ship Pilot Checklists
//

import Foundation

/// A single checklist row (title + checkbox + timestamp + optional quick-note + up to two photos)
public struct ChecklistItem: Codable {
    public var title: String
    public var isChecked: Bool
    public var timestamp: String?
    public var quickNote: String?
    public var photoFilenames: [String]

    public init(
        title: String,
        isChecked: Bool,
        timestamp: String? = nil,
        quickNote: String? = nil,
        photoFilenames: [String] = []
    ) {
        self.title = title
        self.isChecked = isChecked
        self.timestamp = timestamp
        self.quickNote = quickNote
        self.photoFilenames = photoFilenames
    }

    // If you had saved older data under a single-key "photoFilename", let us decode it here:
    private enum CodingKeys: String, CodingKey {
        case title, isChecked, timestamp, quickNote
        case photoFilename   // legacy single-string key
        case photoFilenames  // new array key
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        isChecked = try container.decode(Bool.self, forKey: .isChecked)
        timestamp = try container.decodeIfPresent(String.self, forKey: .timestamp)
        quickNote = try container.decodeIfPresent(String.self, forKey: .quickNote)

        // 1) Try decoding the new array form:
        if let arr = try? container.decode([String].self, forKey: .photoFilenames) {
            photoFilenames = arr
        }
        // 2) Otherwise fall back to the old single-string key:
        else if let single = try container.decodeIfPresent(String.self, forKey: .photoFilename) {
            photoFilenames = [single]
        }
        // 3) If neither was found, use an empty array:
        else {
            photoFilenames = []
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(isChecked, forKey: .isChecked)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(quickNote, forKey: .quickNote)
        try container.encode(photoFilenames, forKey: .photoFilenames)
    }
}
