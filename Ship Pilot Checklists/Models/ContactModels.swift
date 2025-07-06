//
//  ContactModels.swift
//  Ship Pilot Checklists
//

import Foundation

// MARK: - Emergency Contact Model (for backward compatibility)
struct EmergencyContact: Codable {
    var name: String
    var phone: String
}

// MARK: - Contact Model
struct OperationalContact: Codable {
    let id: UUID
    var name: String
    var role: String?
    var organization: String?
    var phone: String
    var email: String?
    var vhfChannel: String?
    var callSign: String?
    var notes: String?
    var port: String?
    var lastUsed: Date?
    var isFavorite: Bool = false
    
    init(name: String, phone: String) {
        self.id = UUID()
        self.name = name
        self.phone = phone
        self.lastUsed = Date()
    }
}

// MARK: - Category Model
struct ContactCategory: Codable {
    var id: UUID
    var name: String
    var contacts: [OperationalContact]
    var isSystemCategory: Bool // true for default categories, false for user-created
    
    init(name: String, isSystemCategory: Bool = false) {
        self.id = UUID()
        self.name = name
        self.contacts = []
        self.isSystemCategory = isSystemCategory
    }
}

// MARK: - Contact Manager
class ContactsManager {
    static let shared = ContactsManager()
    private let defaultsKey = "OperationalContactCategories"
    
    private init() {}
    
    // Default category names - Updated with new categories and order
    static let defaultCategories = [
        "Emergency",
        "Coast Guard",
        "Tug Services",
        "Dispatch",
        "Terminal Operations",
        "Local Authorities",
        "Vessel Agent",
        "Pilot Boat Operators"
    ]
    
    // MARK: - Load Categories
    func loadCategories() -> [ContactCategory] {
        // Try to load saved categories
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let saved = try? JSONDecoder().decode([ContactCategory].self, from: data) {
            return saved
        }
        
        // If no saved data, create default categories
        let defaultCats = Self.defaultCategories.map {
            ContactCategory(name: $0, isSystemCategory: true)
        }
        
        // Save the defaults
        saveCategories(defaultCats)
        return defaultCats
    }
    
    // MARK: - Save Categories
    func saveCategories(_ categories: [ContactCategory]) {
        if let data = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
    
    // MARK: - Add Category
    func addCategory(name: String, to categories: inout [ContactCategory]) {
        let newCategory = ContactCategory(name: name, isSystemCategory: false)
        categories.append(newCategory)
        saveCategories(categories)
    }
    
    // MARK: - Delete Category
    func deleteCategory(at index: Int, from categories: inout [ContactCategory]) {
        // Don't allow deletion of system categories
        guard !categories[index].isSystemCategory else { return }
        categories.remove(at: index)
        saveCategories(categories)
    }
    
    // MARK: - Add Contact
    func addContact(_ contact: OperationalContact, to categoryIndex: Int, in categories: inout [ContactCategory]) {
        categories[categoryIndex].contacts.append(contact)
        saveCategories(categories)
    }
    
    // MARK: - Update Contact
    func updateContact(_ contact: OperationalContact, at indexPath: IndexPath, in categories: inout [ContactCategory]) {
        categories[indexPath.section].contacts[indexPath.row] = contact
        saveCategories(categories)
    }
    
    // MARK: - Delete Contact
    func deleteContact(at indexPath: IndexPath, from categories: inout [ContactCategory]) {
        categories[indexPath.section].contacts.remove(at: indexPath.row)
        saveCategories(categories)
    }
    
    // MARK: - Move Contact
    func moveContact(from source: IndexPath, to destination: IndexPath, in categories: inout [ContactCategory]) {
        let contact = categories[source.section].contacts.remove(at: source.row)
        categories[destination.section].contacts.insert(contact, at: destination.row)
        saveCategories(categories)
    }
    
    // MARK: - Search
    func searchContacts(in categories: [ContactCategory], query: String) -> [(contact: OperationalContact, category: String)] {
        let lowercased = query.lowercased()
        var results: [(contact: OperationalContact, category: String)] = []
        
        for category in categories {
            for contact in category.contacts {
                if contact.name.lowercased().contains(lowercased) ||
                   contact.phone.contains(query) ||
                   contact.organization?.lowercased().contains(lowercased) == true ||
                   contact.role?.lowercased().contains(lowercased) == true {
                    results.append((contact, category.name))
                }
            }
        }
        
        return results
    }
    
    // MARK: - Update Last Used
    func updateLastUsed(for contactId: UUID, in categories: inout [ContactCategory]) {
        for i in 0..<categories.count {
            if let index = categories[i].contacts.firstIndex(where: { $0.id == contactId }) {
                categories[i].contacts[index].lastUsed = Date()
                saveCategories(categories)
                return
            }
        }
    }
    
    // MARK: - Get Frequently Used
    func getFrequentlyUsed(from categories: [ContactCategory], limit: Int = 5) -> [OperationalContact] {
        let allContacts = categories.flatMap { $0.contacts }
        return allContacts
            .sorted { ($0.lastUsed ?? Date.distantPast) > ($1.lastUsed ?? Date.distantPast) }
            .prefix(limit)
            .map { $0 }
    }
}
