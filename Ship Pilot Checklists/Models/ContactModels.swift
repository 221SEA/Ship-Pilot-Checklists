//
//  ContactModels.swift
//  Ship Pilot Checklists
//

import Foundation
import UIKit

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

// MARK: - Enhanced ContactsManager with Robust Persistence
class ContactsManager {
    static let shared = ContactsManager()
    
    // Use Documents directory instead of UserDefaults for better persistence
    private let contactsFileName = "operational_contacts.json"
    private let backupFileName = "operational_contacts_backup.json"
    private let oldDefaultsKey = "OperationalContactCategories"
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private var contactsFileURL: URL {
        documentsDirectory.appendingPathComponent(contactsFileName)
    }
    
    private var backupFileURL: URL {
        documentsDirectory.appendingPathComponent(backupFileName)
    }
    
    private init() {
        // Migrate from UserDefaults to file system on first launch after update
        migrateFromUserDefaultsIfNeeded()
    }
    
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
    
    // MARK: - Migration from UserDefaults
    private func migrateFromUserDefaultsIfNeeded() {
        // Check if we already have data in the file system
        if FileManager.default.fileExists(atPath: contactsFileURL.path) {
            print("📁 Contacts file already exists, no migration needed")
            return
        }
        
        // Check if we have old data in UserDefaults
        if let oldData = UserDefaults.standard.data(forKey: oldDefaultsKey),
           let oldCategories = try? JSONDecoder().decode([ContactCategory].self, from: oldData) {
            
            print("🔄 Migrating \(oldCategories.count) contact categories from UserDefaults to file system")
            
            // Save to file system
            saveCategories(oldCategories)
            
            // Clear old UserDefaults data
            UserDefaults.standard.removeObject(forKey: oldDefaultsKey)
            
            print("✅ Migration complete - contacts moved to Documents directory")
        } else {
            print("📁 No existing contacts found, will create defaults on first load")
        }
    }
    
    // MARK: - Load Categories with Backup Recovery
    func loadCategories() -> [ContactCategory] {
        // Try to load from primary file
        if let categories = loadCategoriesFromFile(contactsFileURL) {
            print("📁 Loaded \(categories.count) categories from primary file")
            return categories
        }
        
        // If primary file failed, try backup
        if let categories = loadCategoriesFromFile(backupFileURL) {
            print("🔄 Primary file failed, loaded \(categories.count) categories from backup")
            
            // Restore backup to primary file
            saveCategories(categories)
            return categories
        }
        
        // If both files failed, create defaults
        print("📁 No saved data found, creating default categories")
        let defaultCats = Self.defaultCategories.map { categoryName in
            ContactCategory(name: categoryName, isSystemCategory: categoryName == "Emergency")
        }
        
        // Save the defaults
        saveCategories(defaultCats)
        return defaultCats
    }
    
    private func loadCategoriesFromFile(_ fileURL: URL) -> [ContactCategory]? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let categories = try JSONDecoder().decode([ContactCategory].self, from: data)
            
            // Validate data integrity
            guard !categories.isEmpty else {
                print("⚠️ Loaded empty categories array from \(fileURL.lastPathComponent)")
                return nil
            }
            
            return categories
        } catch {
            print("❌ Error loading from \(fileURL.lastPathComponent): \(error)")
            return nil
        }
    }
    
    // MARK: - Enhanced Save with Backup
    func saveCategories(_ categories: [ContactCategory]) {
        // Create backup of current data before saving new data
        if FileManager.default.fileExists(atPath: contactsFileURL.path) {
            do {
                // Copy current file to backup
                if FileManager.default.fileExists(atPath: backupFileURL.path) {
                    try FileManager.default.removeItem(at: backupFileURL)
                }
                try FileManager.default.copyItem(at: contactsFileURL, to: backupFileURL)
                print("💾 Created backup of contacts")
            } catch {
                print("⚠️ Could not create backup: \(error)")
            }
        }
        
        // Save new data
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(categories)
            
            // Write atomically to prevent corruption
            try data.write(to: contactsFileURL, options: .atomic)
            
            print("💾 Saved \(categories.count) categories to \(contactsFileURL.lastPathComponent)")
            
            // Verify the save worked
            if let verifyData = try? Data(contentsOf: contactsFileURL),
               let _ = try? JSONDecoder().decode([ContactCategory].self, from: verifyData) {
                print("✅ Save verification successful")
            } else {
                print("⚠️ Save verification failed")
            }
            
        } catch {
            print("❌ Error saving contacts: \(error)")
            
            // Show user-facing error if this is a critical failure
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    
                    let alert = UIAlertController(
                        title: "Save Error",
                        message: "Could not save contacts. Please try again or contact support if the problem persists.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    rootVC.present(alert, animated: true)
                }
            }
        }
    }
    
    // MARK: - Data Recovery Methods
    func createManualBackup() -> Bool {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
        let manualBackupURL = documentsDirectory.appendingPathComponent("contacts_manual_backup_\(timestamp).json")
        
        do {
            if FileManager.default.fileExists(atPath: contactsFileURL.path) {
                try FileManager.default.copyItem(at: contactsFileURL, to: manualBackupURL)
                print("📋 Manual backup created: \(manualBackupURL.lastPathComponent)")
                return true
            }
        } catch {
            print("❌ Manual backup failed: \(error)")
        }
        return false
    }
    
    func getDataFileInfo() -> (primaryExists: Bool, backupExists: Bool, primarySize: Int64, backupSize: Int64) {
        let primaryExists = FileManager.default.fileExists(atPath: contactsFileURL.path)
        let backupExists = FileManager.default.fileExists(atPath: backupFileURL.path)
        
        let primarySize: Int64 = {
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: contactsFileURL.path) else { return 0 }
            return attrs[.size] as? Int64 ?? 0
        }()
        
        let backupSize: Int64 = {
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: backupFileURL.path) else { return 0 }
            return attrs[.size] as? Int64 ?? 0
        }()
        
        return (primaryExists, backupExists, primarySize, backupSize)
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
    
    // MARK: - Enhanced Move Contact with Crash Prevention
    func moveContact(from source: IndexPath, to destination: IndexPath, in categories: inout [ContactCategory]) {
        // Validate source indices
        guard source.section >= 0 && source.section < categories.count else {
            print("❌ Invalid source section: \(source.section), categories count: \(categories.count)")
            return
        }
        
        guard source.row >= 0 && source.row < categories[source.section].contacts.count else {
            print("❌ Invalid source row: \(source.row), contacts count in section \(source.section): \(categories[source.section].contacts.count)")
            return
        }
        
        // Validate destination indices
        guard destination.section >= 0 && destination.section < categories.count else {
            print("❌ Invalid destination section: \(destination.section), categories count: \(categories.count)")
            return
        }
        
        // For destination row, allow inserting at the end (count is valid for insertion)
        guard destination.row >= 0 && destination.row <= categories[destination.section].contacts.count else {
            print("❌ Invalid destination row: \(destination.row), contacts count in section \(destination.section): \(categories[destination.section].contacts.count)")
            return
        }
        
        // Don't move to the same position
        if source == destination {
            print("ℹ️ Source and destination are the same, no move needed")
            return
        }
        
        print("📝 Moving contact from [\(source.section), \(source.row)] to [\(destination.section), \(destination.row)]")
        
        // Perform the move safely
        let contact = categories[source.section].contacts.remove(at: source.row)
        
        // Adjust destination row if moving within the same section and destination is after source
        let adjustedDestinationRow: Int
        if source.section == destination.section && destination.row > source.row {
            adjustedDestinationRow = destination.row - 1
        } else {
            adjustedDestinationRow = destination.row
        }
        
        // Final bounds check for adjusted destination
        let finalDestinationRow = min(adjustedDestinationRow, categories[destination.section].contacts.count)
        
        categories[destination.section].contacts.insert(contact, at: finalDestinationRow)
        
        print("✅ Successfully moved contact: \(contact.name)")
        
        // Save the changes
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
