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
    var isSystemCategory: Bool // true for Emergency category only, false for all others
    
    init(name: String, isSystemCategory: Bool = false) {
        self.id = UUID()
        self.name = name
        self.contacts = []
        self.isSystemCategory = isSystemCategory
    }
    
    init(name: String, contacts: [OperationalContact], isSystemCategory: Bool = false) {
        self.id = UUID()
        self.name = name
        self.contacts = contacts
        self.isSystemCategory = isSystemCategory
    }
}

// MARK: - Contact Manager
class ContactsManager {
    static let shared = ContactsManager()
    private let defaultsKey = "OperationalContactCategories"
    
    private init() {}
    
    // Default category names - Only Emergency is protected
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
            
            // DEBUG: Print what was loaded
            print("Loaded from UserDefaults:")
            for category in saved {
                print("  \(category.name): isSystemCategory = \(category.isSystemCategory)")
            }
            
            return saved
        }
        
        // If no saved data, create default categories
        // Only "Emergency" is protected as a system category
        let defaultCats = Self.defaultCategories.map { categoryName in
            ContactCategory(name: categoryName, isSystemCategory: categoryName == "Emergency")
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
    
    // MARK: - Add Category with Contacts
    func addCategory(name: String, contacts: [OperationalContact], to categories: inout [ContactCategory]) {
        let newCategory = ContactCategory(name: name, contacts: contacts, isSystemCategory: false)
        categories.append(newCategory)
        saveCategories(categories)
    }
    
    // MARK: - Delete Category
    func deleteCategory(at index: Int, from categories: inout [ContactCategory]) -> Bool {
        // Don't allow deletion of Emergency category
        guard !categories[index].isSystemCategory else { return false }
        
        // Check if category has contacts
        let category = categories[index]
        if !category.contacts.isEmpty {
            // Return false to indicate confirmation needed
            return false
        }
        
        categories.remove(at: index)
        saveCategories(categories)
        return true
    }

    // MARK: - Force Delete Category (for confirmed deletions)
    func forceDeleteCategory(at index: Int, from categories: inout [ContactCategory]) {
        // Don't allow deletion of Emergency category
        guard !categories[index].isSystemCategory else { return }
        categories.remove(at: index)
        saveCategories(categories)
    }

    // MARK: - Move Category
    func moveCategory(from sourceIndex: Int, to destinationIndex: Int, in categories: inout [ContactCategory]) {
        let sourceCategory = categories[sourceIndex]
        let destinationCategory = categories[destinationIndex]
        
        // Don't allow moving the Emergency category
        guard !sourceCategory.isSystemCategory else { return }
        
        // Don't allow non-Emergency categories to move into Emergency position if Emergency is there
        if destinationCategory.isSystemCategory {
            return
        }
        
        let category = categories.remove(at: sourceIndex)
        categories.insert(category, at: destinationIndex)
        saveCategories(categories)
    }

    // MARK: - Check if Category Can Be Deleted
    func canDeleteCategory(at index: Int, in categories: [ContactCategory]) -> (canDelete: Bool, reason: String?) {
        let category = categories[index]
        
        if category.isSystemCategory {
            return (false, "The Emergency category cannot be deleted as it's required for the SMS feature")
        }
        
        if !category.contacts.isEmpty {
            let contactCount = category.contacts.count
            let message = contactCount == 1 ?
                "This category contains 1 contact. Delete anyway?" :
                "This category contains \(contactCount) contacts. Delete anyway?"
            return (false, message)
        }
        
        return (true, nil)
    }

    // MARK: - Check if Category Can Be Renamed
    func canRenameCategory(at index: Int, in categories: [ContactCategory]) -> (canRename: Bool, reason: String?) {
        let category = categories[index]
        
        if category.isSystemCategory {
            return (false, "The Emergency category cannot be renamed as it's required for the SMS feature")
        }
        
        return (true, nil)
    }
    
    // MARK: - Bulk Add Contacts
    func addContacts(_ contacts: [OperationalContact], toCategoryNamed name: String, in categories: inout [ContactCategory]) {
        if let index = categories.firstIndex(where: { $0.name == name }) {
            categories[index].contacts.append(contentsOf: contacts)
        } else {
            let newCategory = ContactCategory(name: name, contacts: contacts)
            categories.append(newCategory)
        }
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
