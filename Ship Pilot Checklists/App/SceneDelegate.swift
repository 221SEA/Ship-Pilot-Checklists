//
//  SceneDelegate.swift
//  Ship Pilot Checklists
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        // 1) Grab the scene
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // 2) Create our window
        let window = UIWindow(windowScene: windowScene)
        
        // 3) Paint the window background
        window.backgroundColor = ThemeManager.backgroundColor(for: window.traitCollection)
        
        // 4) Build our nav stack
        let mainVC = MainViewController()
        let nav = UINavigationController(rootViewController: mainVC)
        
        // 5) Configure an opaque nav-bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = ThemeManager.navBarColor(for: window.traitCollection)
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: ThemeManager.navBarForegroundColor(for: window.traitCollection)
        ]
        
        nav.navigationBar.standardAppearance = appearance
        nav.navigationBar.scrollEdgeAppearance  = appearance
        nav.navigationBar.compactAppearance      = appearance
        nav.navigationBar.compactScrollEdgeAppearance = appearance
        nav.navigationBar.tintColor = ThemeManager.navBarForegroundColor(for: window.traitCollection)
        
        // 6) Install and show
        window.rootViewController = nav
        window.makeKeyAndVisible()
        self.window = window
        
        // 7) Apply the rest of our theme
        ThemeManager.applyToCurrentWindow()
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            print("❌ No URL provided to scene delegate")
            return
        }
        
        print("📁 SceneDelegate received URL: \(url)")
        print("📁 File extension: \(url.pathExtension)")
        print("📁 URL scheme: \(url.scheme ?? "none")")
        print("📁 URL path: \(url.path)")

        switch url.pathExtension.lowercased() {
        case "shipchecklist":
            print("📋 Processing checklist file")
            importChecklist(from: url)
        case "csv":
            print("📊 Processing CSV file")
            handleCSVImport(from: url)
        case "json":
            print("📄 Processing JSON file")
            handleJSONImport(from: url)
        default:
            print("❌ Unknown file type: \(url.pathExtension)")
            
            // Show alert for unknown file type
            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: "Unsupported File Type",
                    message: "File type '.\(url.pathExtension)' is not supported. Please use CSV or JSON files for contacts.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController?.present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - JSON Import Handling
    private func handleJSONImport(from url: URL) {
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            DispatchQueue.main.async {
                self.showImportError(error: NSError(domain: "", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "Could not access the file. Please try importing from within the app."
                ]))
            }
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            let data = try Data(contentsOf: url)
            
            // Try to decode as contacts first
            if let contacts = try? JSONDecoder().decode([ContactCategory].self, from: data) {
                importContactsFromJSON(contacts: contacts, fileName: url.lastPathComponent)
                return
            }
            
            // Try to decode as checklist
            if let checklist = try? JSONDecoder().decode(CustomChecklist.self, from: data) {
                var importedChecklist = checklist
                importedChecklist.id = UUID() // Give it a new ID
                
                DispatchQueue.main.async {
                    self.showImportConfirmation(for: importedChecklist)
                }
                return
            }
            
            // If neither worked, show error
            throw NSError(domain: "", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "JSON file format not recognized. Expected contacts or checklist data."
            ])
            
        } catch {
            DispatchQueue.main.async {
                self.showImportError(error: error)
            }
        }
    }

    private func importContactsFromJSON(contacts: [ContactCategory], fileName: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
        let prefixedCategories = contacts.map { original in
            var copy = original
            copy.name = "Imported – \(original.name) (\(timestamp))"
            copy.isSystemCategory = false // Imported categories are never system categories
            return copy
        }

        let allCategories = ContactsManager.shared.loadCategories() + prefixedCategories
        ContactsManager.shared.saveCategories(allCategories)

        DispatchQueue.main.async {
            let contactCount = prefixedCategories.reduce(0) { $0 + $1.contacts.count }
            let categoryCount = prefixedCategories.count
            
            // FIXED: Send notification to update UI
            NotificationCenter.default.post(name: NSNotification.Name("ContactsImported"), object: nil, userInfo: [
                "categoryName": prefixedCategories.first?.name ?? "Imported JSON",
                "contactCount": contactCount,
                "generatedNames": 0,
                "skippedRows": 0
            ])
            
            let message = contactCount == 1
                ? "1 contact imported from \(fileName)."
                : "\(contactCount) contacts imported from \(fileName) in \(categoryCount) \(categoryCount == 1 ? "category" : "categories")."
            
            let alert = UIAlertController(
                title: "Contacts Imported Successfully",
                message: message,
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "View Imported", style: .default) { _ in
                if let firstCategoryName = prefixedCategories.first?.name {
                    NotificationCenter.default.post(name: NSNotification.Name("NavigateToImportedContacts"), object: firstCategoryName)
                }
            })
            
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(alert, animated: true)
            }
        }
    }
    
    // MARK: - Enhanced CSV Import Handling
    // MARK: - Enhanced CSV Import Handling
    private func handleCSVImport(from url: URL) {
        print("🔄 Starting CSV import from: \(url)")
        
        // Start accessing security-scoped resource
        let hasAccess = url.startAccessingSecurityScopedResource()
        print("📱 Security-scoped resource access: \(hasAccess)")
        
        // Always stop accessing when done
        defer {
            if hasAccess {
                url.stopAccessingSecurityScopedResource()
                print("✅ Released security-scoped resource")
            }
        }
        
        do {
            // Try to copy the file to a temporary location first
            let tempDirectory = FileManager.default.temporaryDirectory
            let tempURL = tempDirectory.appendingPathComponent(url.lastPathComponent)
            
            // Remove any existing temp file
            try? FileManager.default.removeItem(at: tempURL)
            
            // Copy the file to temp location
            try FileManager.default.copyItem(at: url, to: tempURL)
            print("📄 Copied file to temporary location: \(tempURL)")
            
            // Now read from the temporary file
            let content = try String(contentsOf: tempURL)
            print("Successfully read file content, length: \(content.count)")
            
            let firstLine = content.components(separatedBy: .newlines).first ?? ""
            print("First line: \(firstLine)")
            
            // Check if it looks like a checklist CSV (Priority,Item) or contacts CSV
            if firstLine.lowercased().contains("priority") && firstLine.lowercased().contains("item") {
                print("Detected as checklist CSV")
                importChecklistFromCSV(url: tempURL)
            } else if isContactsCSV(firstLine: firstLine) {
                print("Detected as contacts CSV")
                importContactsFromCSV(from: tempURL)
            } else {
                print("CSV type unclear, asking user")
                DispatchQueue.main.async {
                    self.showCSVTypeSelectionAlert(for: tempURL)
                }
            }
            
            // Clean up temp file after import
            try? FileManager.default.removeItem(at: tempURL)
            
        } catch {
            print("Error reading file: \(error)")
            DispatchQueue.main.async {
                self.showImportError(error: error)
            }
        }
    }

    private func isContactsCSV(firstLine: String) -> Bool {
        let lowercased = firstLine.lowercased()
        
        // Expanded list of contact-related field indicators
        let contactFields = [
            // Name variations
            "name", "contact name", "full name", "contact", "person",
            // Phone variations
            "phone", "mobile", "cell", "telephone", "tel", "phone number",
            // Communication
            "email", "e-mail", "mail",
            // Organization
            "organization", "company", "org", "employer", "business",
            // Role/Position
            "role", "title", "job title", "position", "rank",
            // Maritime specific
            "vhf", "call sign", "callsign", "port", "harbor",
            // Category field (NEW)
            "category", "group", "type"
        ]
        
        let foundFields = contactFields.filter { lowercased.contains($0) }
        print("CSV field detection - found fields: \(foundFields)")
        return foundFields.count >= 2 // If we find at least 2 contact-related fields
    }

    private func showCSVTypeSelectionAlert(for url: URL) {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                
                let alert = UIAlertController(
                    title: "Import CSV",
                    message: "What type of CSV file is this?",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "Checklist", style: .default) { _ in
                    self.importChecklistFromCSV(url: url)
                })
                
                alert.addAction(UIAlertAction(title: "Contacts", style: .default) { _ in
                    self.importContactsFromCSV(from: url)
                })
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                
                rootVC.present(alert, animated: true)
            }
        }
    }
    
    // MARK: - ENHANCED CSV Import with Category Support
    private func importContactsFromCSV(from url: URL) {
        print("Starting contacts CSV import with category support")
        
        do {
            let content = try String(contentsOf: url)
            print("File content length: \(content.count)")
            
            // Handle Windows line endings by normalizing them
            let normalizedContent = content.replacingOccurrences(of: "\r\n", with: "\n")
            var rows = normalizedContent.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            print("Found \(rows.count) non-empty rows")

            guard let header = rows.first else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "CSV is empty."])
            }
            
            print("Header: \(header)")

            // Parse header to understand the CSV structure
            let headers = header.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            print("Parsed headers: \(headers)")
            
            // Find column indices for different fields
            let nameIndex = findColumnIndex(in: headers, possibleNames: [
                "name", "contact name", "full name", "contact", "person", "individual"
            ])
            
            let phoneIndex = findColumnIndex(in: headers, possibleNames: [
                "phone", "phone number", "telephone", "mobile", "mobile phone",
                "cell", "cell phone", "cellular", "office phone", "work phone",
                "business phone", "primary phone", "main phone", "tel", "phone#"
            ])
            
            let emailIndex = findColumnIndex(in: headers, possibleNames: [
                "email", "email address", "e-mail", "e mail", "electronic mail",
                "mail", "email addr", "work email", "business email"
            ])
            
            let organizationIndex = findColumnIndex(in: headers, possibleNames: [
                "organization", "company", "org", "employer", "business",
                "corporation", "agency", "department", "firm", "workplace"
            ])
            
            let roleIndex = findColumnIndex(in: headers, possibleNames: [
                "role", "title", "job title", "position", "job", "occupation",
                "rank", "designation", "job position", "work title"
            ])
            
            let vhfIndex = findColumnIndex(in: headers, possibleNames: [
                "vhf", "vhf channel", "radio", "channel", "radio channel",
                "vhf radio", "marine radio", "ship radio", "comm channel"
            ])
            
            let callSignIndex = findColumnIndex(in: headers, possibleNames: [
                "call sign", "callsign", "call_sign", "radio call sign",
                "vessel call sign", "ship call sign", "call letters"
            ])
            
            let portIndex = findColumnIndex(in: headers, possibleNames: [
                "port", "location", "port/location", "base port", "home port",
                "harbor", "marina", "terminal", "facility", "base"
            ])
            
            let notesIndex = findColumnIndex(in: headers, possibleNames: [
                "notes", "comments", "remarks", "additional info", "memo",
                "description", "details", "other", "misc", "miscellaneous"
            ])
            
            // NEW: Find category column
            let categoryIndex = findColumnIndex(in: headers, possibleNames: [
                "category", "group", "type", "contact category", "contact type", "department"
            ])
            
            print("Column indices - Name: \(nameIndex), Phone: \(phoneIndex), Category: \(categoryIndex)")

            guard let nameIdx = nameIndex, let phoneIdx = phoneIndex else {
                throw NSError(domain: "", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "CSV must contain 'Name' and 'Phone' columns.\n\nFound columns: \(headers.joined(separator: ", "))"
                ])
            }

            // Load existing categories for matching
            var allCategories = ContactsManager.shared.loadCategories()
            
            // Parse data rows and group by category
            rows.removeFirst() // Remove header
            var contactsByCategory: [String: [OperationalContact]] = [:]
            var skippedRows = 0
            var generatedNames = 0
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)

            for (rowNum, row) in rows.enumerated() {
                let columns = parseCSVRow(row)
                print("Row \(rowNum + 2): \(columns)")
                
                guard columns.count > max(nameIdx, phoneIdx) else {
                    print("Row \(rowNum + 2) has insufficient columns (\(columns.count)), skipping")
                    skippedRows += 1
                    continue
                }
                
                var name = columns[nameIdx].trimmingCharacters(in: .whitespacesAndNewlines)
                let phone = columns[phoneIdx].trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Check if phone is valid
                guard !phone.isEmpty else {
                    print("Row \(rowNum + 2) missing phone number, skipping")
                    skippedRows += 1
                    continue
                }
                
                // SMART NAME GENERATION: If name is empty, try to generate one
                if name.isEmpty {
                    var generatedName = ""
                    
                    // Try to build name from organization + role
                    if let orgIdx = organizationIndex, orgIdx < columns.count {
                        let org = columns[orgIdx].trimmingCharacters(in: .whitespacesAndNewlines)
                        if !org.isEmpty {
                            generatedName = org
                            
                            // Add role if available
                            if let roleIdx = roleIndex, roleIdx < columns.count {
                                let role = columns[roleIdx].trimmingCharacters(in: .whitespacesAndNewlines)
                                if !role.isEmpty {
                                    generatedName += " \(role)"
                                }
                            }
                        }
                    }
                    
                    // If we still don't have a name, use phone as last resort
                    if generatedName.isEmpty {
                        generatedName = "Contact \(phone)"
                    }
                    
                    name = generatedName
                    generatedNames += 1
                    print("Generated name: '\(name)' for row \(rowNum + 2)")
                }

                var contact = OperationalContact(name: name, phone: phone)
                
                // Add optional fields if available
                if let emailIdx = emailIndex, emailIdx < columns.count {
                    let email = columns[emailIdx].trimmingCharacters(in: .whitespacesAndNewlines)
                    contact.email = email.isEmpty ? nil : email
                }
                if let orgIdx = organizationIndex, orgIdx < columns.count {
                    let org = columns[orgIdx].trimmingCharacters(in: .whitespacesAndNewlines)
                    contact.organization = org.isEmpty ? nil : org
                }
                if let roleIdx = roleIndex, roleIdx < columns.count {
                    let role = columns[roleIdx].trimmingCharacters(in: .whitespacesAndNewlines)
                    contact.role = role.isEmpty ? nil : role
                }
                if let vhfIdx = vhfIndex, vhfIdx < columns.count {
                    let vhf = columns[vhfIdx].trimmingCharacters(in: .whitespacesAndNewlines)
                    contact.vhfChannel = vhf.isEmpty ? nil : vhf
                }
                if let callIdx = callSignIndex, callIdx < columns.count {
                    let callSign = columns[callIdx].trimmingCharacters(in: .whitespacesAndNewlines)
                    contact.callSign = callSign.isEmpty ? nil : callSign
                }
                if let portIdx = portIndex, portIdx < columns.count {
                    let port = columns[portIdx].trimmingCharacters(in: .whitespacesAndNewlines)
                    contact.port = port.isEmpty ? nil : port
                }
                if let notesIdx = notesIndex, notesIdx < columns.count {
                    let notes = columns[notesIdx].trimmingCharacters(in: .whitespacesAndNewlines)
                    contact.notes = notes.isEmpty ? nil : notes
                }

                // NEW: Determine which category this contact belongs to
                var targetCategory = "Imported CSV (\(timestamp))" // Default
                
                if let catIdx = categoryIndex, catIdx < columns.count {
                    let csvCategory = columns[catIdx].trimmingCharacters(in: .whitespacesAndNewlines)
                    if !csvCategory.isEmpty {
                        // Try to find matching existing category (case-insensitive)
                        if let existingCategory = allCategories.first(where: {
                            $0.name.lowercased() == csvCategory.lowercased()
                        }) {
                            targetCategory = existingCategory.name
                            print("Matched to existing category: '\(targetCategory)'")
                        } else {
                            // Use the category name from CSV (new category will be created)
                            targetCategory = csvCategory
                            print("Will create new category: '\(targetCategory)'")
                        }
                    }
                }
                
                // Add contact to the appropriate category group
                contactsByCategory[targetCategory, default: []].append(contact)
                print("Added contact '\(contact.name)' to category '\(targetCategory)'")
            }

            print("Import summary: \(contactsByCategory.values.reduce(0) { $0 + $1.count }) contacts in \(contactsByCategory.count) categories, \(skippedRows) rows skipped, \(generatedNames) names generated")

            guard !contactsByCategory.isEmpty else {
                throw NSError(domain: "", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "No valid contacts found in CSV file. All rows were missing required phone numbers."
                ])
            }

            // Add contacts to their respective categories
            var updatedCategories: [String] = []
            var newCategories: [String] = []
            
            for (categoryName, contacts) in contactsByCategory {
                if let existingIndex = allCategories.firstIndex(where: { $0.name == categoryName }) {
                    // Add to existing category
                    allCategories[existingIndex].contacts.append(contentsOf: contacts)
                    updatedCategories.append(categoryName)
                    print("Added \(contacts.count) contacts to existing category: '\(categoryName)'")
                } else {
                    // Create new category
                    let newCategory = ContactCategory(name: categoryName, contacts: contacts, isSystemCategory: false)
                    allCategories.append(newCategory)
                    newCategories.append(categoryName)
                    print("Created new category '\(categoryName)' with \(contacts.count) contacts")
                }
            }
            
            // Save all categories
            ContactsManager.shared.saveCategories(allCategories)
            print("Saved all categories")

            DispatchQueue.main.async {
                // Prepare detailed message
                let totalContacts = contactsByCategory.values.reduce(0) { $0 + $1.count }
                var message = ""
                
                if totalContacts == 1 {
                    message = "1 contact imported from CSV."
                } else {
                    message = "\(totalContacts) contacts imported from CSV."
                }
                
                // Add category details
                var categoryDetails: [String] = []
                
                if !updatedCategories.isEmpty {
                    let updatedList = updatedCategories.joined(separator: ", ")
                    categoryDetails.append("• Added to existing categories: \(updatedList)")
                }
                
                if !newCategories.isEmpty {
                    let newList = newCategories.joined(separator: ", ")
                    categoryDetails.append("• Created new categories: \(newList)")
                }
                
                if generatedNames > 0 {
                    categoryDetails.append("• \(generatedNames) contact names were auto-generated")
                }
                
                if skippedRows > 0 {
                    categoryDetails.append("• \(skippedRows) rows were skipped due to missing phone numbers")
                }
                
                if !categoryDetails.isEmpty {
                    message += "\n\n" + categoryDetails.joined(separator: "\n")
                }
                
                // Add helpful tip
                message += "\n\n💡 Tip: Include a 'Category' column in your CSV to automatically organize contacts into specific categories."
                
                // Post notification for the first category that received contacts
                let firstCategoryName = updatedCategories.first ?? newCategories.first ?? "Imported CSV"
                NotificationCenter.default.post(name: NSNotification.Name("ContactsImported"), object: nil, userInfo: [
                    "categoryName": firstCategoryName,
                    "contactCount": totalContacts,
                    "generatedNames": generatedNames,
                    "skippedRows": skippedRows
                ])
                
                let alert = UIAlertController(
                    title: "CSV Import Successful",
                    message: message,
                    preferredStyle: .alert
                )
                
                // Add "View Imported" button
                alert.addAction(UIAlertAction(title: "View Imported", style: .default) { _ in
                    // Navigate to the first category that received imports
                    NotificationCenter.default.post(name: NSNotification.Name("NavigateToImportedContacts"), object: firstCategoryName)
                })
                
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController?.present(alert, animated: true)
                }
            }

        } catch {
            print("CSV import error: \(error)")
            DispatchQueue.main.async {
                self.showImportError(error: error)
            }
        }
    }
    
    // MARK: - Checklist Import
    private func importChecklist(from url: URL) {
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            DispatchQueue.main.async {
                self.showImportError(error: NSError(domain: "", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "Could not access the file."
                ]))
            }
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            // Read the file data
            let data = try Data(contentsOf: url)
            
            // Decode the checklist
            let decoder = JSONDecoder()
            var importedChecklist = try decoder.decode(CustomChecklist.self, from: data)
            
            // Give it a new ID and mark as not imported yet
            importedChecklist.id = UUID()
            
            // Show import confirmation
            DispatchQueue.main.async {
                self.showImportConfirmation(for: importedChecklist)
            }
            
        } catch {
            DispatchQueue.main.async {
                self.showImportError(error: error)
            }
        }
    }
    
    func importChecklistFromCSV(url: URL) {
        print("📋 Starting checklist CSV import from: \(url)")
        
        do {
            // Try to read the file directly first
            let content = try String(contentsOf: url, encoding: .utf8)
            print("✅ Successfully read CSV file, length: \(content.count)")
            
            var rows = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

            // ✅ Step 1: Validate header
            guard let header = rows.first else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "CSV is empty."])
            }

            let expectedHeader = ["Priority", "Item"]
            let parsedHeader = header.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

            guard Array(parsedHeader.prefix(expectedHeader.count)) == expectedHeader else {
                throw NSError(domain: "", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "Invalid CSV header. Expected: \"Priority,Item\""
                ])
            }

            // ✅ Step 2: Parse rows and group by section
            rows.removeFirst() // Remove header
            var groupedItems: [String: [ChecklistItem]] = [:]

            for row in rows {
                let columns = row.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                guard columns.count >= 2 else { continue }

                let priority = columns[0]
                let itemTitle = columns[1]

                let item = ChecklistItem(
                    title: itemTitle,
                    isChecked: false
                )

                groupedItems[priority, default: []].append(item)
            }

            // ✅ Step 3: Convert grouped items into sections
            let sections = groupedItems.map { (sectionTitle, items) in
                ChecklistSection(title: sectionTitle, items: items)
            }.sorted(by: { $0.title < $1.title }) // Optional: sort sections alphabetically

            let checklist = CustomChecklist(
                title: url.deletingPathExtension().lastPathComponent,
                sections: sections
            )

            DispatchQueue.main.async {
                self.showImportConfirmation(for: checklist)
            }

        } catch {
            print("❌ Error reading CSV file: \(error)")
            DispatchQueue.main.async {
                self.showImportError(error: error)
            }
        }
    }
    
    private func showImportConfirmation(for checklist: CustomChecklist) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            
            let alert = UIAlertController(
                title: "Import Checklist",
                message: "Do you want to import '\(checklist.title)'?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            alert.addAction(UIAlertAction(title: "Import", style: .default) { _ in
                // Add to custom checklists
                CustomChecklistManager.shared.add(checklist)
                // Post notification to refresh the list
                NotificationCenter.default.post(name: NSNotification.Name("ChecklistImported"), object: nil)
                            
                // Show success message
                let successAlert = UIAlertController(
                    title: "Success",
                    message: "'\(checklist.title)' has been imported to your Custom Checklists.",
                    preferredStyle: .alert
                )
                successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                rootVC.present(successAlert, animated: true)
            })
            
            rootVC.present(alert, animated: true)
        }
    }
    
    private func showImportError(error: Error) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            
            let alert = UIAlertController(
                title: "Import Failed",
                message: "Could not import: \(error.localizedDescription)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            rootVC.present(alert, animated: true)
        }
    }
    
    // MARK: - Helper Functions
    private func findColumnIndex(in headers: [String], possibleNames: [String]) -> Int? {
        // First, try exact matches
        for name in possibleNames {
            if let index = headers.firstIndex(of: name) {
                print("Found exact match for '\(name)' at column \(index)")
                return index
            }
        }
        
        // If no exact match, try partial matches (helpful for variations)
        for (headerIndex, header) in headers.enumerated() {
            for name in possibleNames {
                if header.contains(name) {
                    print("Found partial match: '\(header)' contains '\(name)' at column \(headerIndex)")
                    return headerIndex
                }
            }
        }
        
        print("No match found for possible names: \(possibleNames)")
        return nil
    }

    private func parseCSVRow(_ row: String) -> [String] {
        // Simple CSV parser that handles quoted fields
        var columns: [String] = []
        var currentColumn = ""
        var insideQuotes = false
        var i = row.startIndex
        
        while i < row.endIndex {
            let char = row[i]
            
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                columns.append(currentColumn)
                currentColumn = ""
            } else {
                currentColumn.append(char)
            }
            
            i = row.index(after: i)
        }
        
        // Don't forget the last column
        columns.append(currentColumn)
        
        return columns
    }
    
    // MARK: - Scene Lifecycle
    func sceneDidDisconnect(_ scene: UIScene) { }
    func sceneDidBecomeActive(_ scene: UIScene) { }
    func sceneWillResignActive(_ scene: UIScene) { }
    func sceneWillEnterForeground(_ scene: UIScene) { }
    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
}
