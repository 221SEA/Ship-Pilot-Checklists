//
//  CustomChecklistManager.swift
//  Ship Pilot Checklists
//

import Foundation

class CustomChecklistManager {

    static let shared = CustomChecklistManager()

    private let key = "customChecklists"

    private init() {}

    func saveAll(_ checklists: [CustomChecklist]) {
        if let data = try? JSONEncoder().encode(checklists) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func loadAll() -> [CustomChecklist] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let checklists = try? JSONDecoder().decode([CustomChecklist].self, from: data) else {
            return []
        }
        return checklists.reversed()
    }

    func add(_ checklist: CustomChecklist) {
        var all = loadAll()
        all.append(checklist)
        saveAll(all)
    }

    func update(_ updated: CustomChecklist) {
        var all = loadAll()
        if let index = all.firstIndex(where: { $0.id == updated.id }) {
            all[index] = updated
            saveAll(all)
        }
    }

    func delete(_ checklist: CustomChecklist) {
        var all = loadAll()
        all.removeAll { $0.id == checklist.id }
        saveAll(all)
    }
}
