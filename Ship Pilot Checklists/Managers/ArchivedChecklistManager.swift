//  ArchivedChecklistManager.swift
//  Ship Pilot Checklists
//

import Foundation

/// A wrapper enum so we can archive either kind of checklist
enum ArchivedChecklist: Codable {
    case builtIn(ChecklistInfo)
    case custom(CustomChecklist)

    private enum CodingKeys: String, CodingKey {
        case type, builtIn, custom
    }
    private enum ChecklistType: String, Codable {
        case builtIn, custom
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ChecklistType.self, forKey: .type)
        switch type {
        case .builtIn:
            let info = try container.decode(ChecklistInfo.self, forKey: .builtIn)
            self = .builtIn(info)
        case .custom:
            let custom = try container.decode(CustomChecklist.self, forKey: .custom)
            self = .custom(custom)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .builtIn(let info):
            try container.encode(ChecklistType.builtIn, forKey: .type)
            try container.encode(info, forKey: .builtIn)
        case .custom(let custom):
            try container.encode(ChecklistType.custom, forKey: .type)
            try container.encode(custom, forKey: .custom)
        }
    }
}

/// Manages your archive list in UserDefaults
class ArchivedChecklistManager {
    static let shared = ArchivedChecklistManager()
    private let key = "archivedChecklists"
    private init() {}

    func loadAll() -> [ArchivedChecklist] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([ArchivedChecklist].self, from: data)
        else { return [] }
        return list
    }

    private func saveAll(_ list: [ArchivedChecklist]) {
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func add(_ item: ArchivedChecklist) {
        var all = loadAll()
        all.append(item)
        saveAll(all)
    }

    func delete(_ item: ArchivedChecklist) {
        var all = loadAll()
        all.removeAll { archived in
            // crude equality: same case & same id/title
            switch (archived, item) {
            case (.builtIn(let a), .builtIn(let b)):
                return a.title == b.title
            case (.custom(let a), .custom(let b)):
                return a.id == b.id
            default:
                return false
            }
        }
        saveAll(all)
    }

    func clearAll() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
