//
//  CustomChecklist.swift
//  Ship Pilot Checklists
//

import Foundation

/// A user‐created checklist (with a stable UUID, a title, and multiple sections).
/// Conforms to Codable so we can save/load it from disk.
public struct CustomChecklist: Codable {
    public var id: UUID
    public var title: String
    public var sections: [ChecklistSection]
    public var isFavorite: Bool = false

    public init(
        id: UUID = UUID(),
        title: String,
        sections: [ChecklistSection],
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.sections = sections
        self.isFavorite = isFavorite
    }
}
