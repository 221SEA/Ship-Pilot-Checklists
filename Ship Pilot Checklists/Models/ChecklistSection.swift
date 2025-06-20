//
//  ChecklistSection.swift
//  Ship Pilot Checklists
//

import Foundation

/// A single section in a checklist (e.g. “High Priority” / “Medium Priority” / etc.).
/// Contains a title + the array of ChecklistItem.
public struct ChecklistSection: Codable {
    public var title: String
    public var items: [ChecklistItem]

    public init(title: String, items: [ChecklistItem]) {
        self.title = title
        self.items = items
    }
}
