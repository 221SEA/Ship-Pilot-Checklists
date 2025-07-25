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
        guard let url = URLContexts.first?.url else { return }

        switch url.pathExtension.lowercased() {
        case "shipchecklist":
            importChecklist(from: url)
        case "csv":
            // Enhanced: Handle both checklist and contact CSVs
            handleCSVImport(from: url)
        case "shipcontacts":
            // Enhanced: Better feedback and error handling
            importContactsFromShipContactsFile(from: url)
        default:
            break
        }
    }
    
    // MARK: - Enhanced CSV Handling
    private func handleCSVImport(from url: URL) {
        do {
            let content = try String(contentsOf: url)
            let firstLine = content.components(separatedBy: .newlines).first ?? ""
            
            // Check if it looks like a checklist CSV (Priority,Item) or contacts CSV
            if firstLine.lowercased().contains("priority") && firstLine.lowercased().contains("item") {
                // It's a checklist CSV
                importChecklistFromCSV(url: url)
            } else if isContactsCSV(firstLine: firstLine) {
                // It's a contacts CSV
                importContactsFromCSV(from: url)
            } else {
                // Ask the user what type it is
                DispatchQueue.main.async {
                    self.showCSVTypeSelectionAlert(for: url)
                }
            }
        } catch {
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
            "vhf", "call sign", "callsign", "port", "harbor"
        ]
        
        let foundFields = contactFields.filter { lowercased.contains($0) }
        return foundFields.count >= 2 // If we find at least 2 contact-related fields
    }

    private func showCSVTypeSelectionAlert(for url: URL) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else { return }
        
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
    
    // MARK: - Enhanced Ship Contacts File Import
    private func importContactsFromShipContactsFile(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let importedCategories = try decoder.decode([ContactCategory].self, from: data)

            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
            let prefixedCategories = importedCategories.map { original in
                var copy = original
                copy.name = "Imported – \(original.name) (\(timestamp))"
                return copy
            }

            let allCategories = ContactsManager.shared.loadCategories() + prefixedCategories
            ContactsManager.shared.saveCategories(allCategories)

            DispatchQueue.main.async {
                let contactCount = prefixedCategories.reduce(0) { $0 + $1.contacts.count }
                let categoryCount = prefixedCategories.count
                
                let message = contactCount == 1
                    ? "1 contact imported in \(categoryCount) category."
                    : "\(contactCount) contacts imported in \(categoryCount) \(categoryCount == 1 ? "category" : "categories")."
                
                let alert = UIAlertController(
                    title: "Contacts Imported Successfully",
                    message: message,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
            }

        } catch {
            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: "Import Failed",
                    message: "Unable to read contacts file: \(error.localizedDescription)",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
            }
        }
    }
    
    // MARK: - NEW: CSV Contacts Import
    private func importContactsFromCSV(from url: URL) {
        do {
            let content = try String(contentsOf: url)
            var rows = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

            guard let header = rows.first else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "CSV is empty."])
            }

            // Parse header to understand the CSV structure
            let headers = header.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            
            // Find column indices for different fields - Enhanced recognition
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

            guard let nameIdx = nameIndex, let phoneIdx = phoneIndex else {
                throw NSError(domain: "", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "CSV must contain 'Name' and 'Phone' columns.\n\nFound columns: \(headers.joined(separator: ", "))"
                ])
            }

            // Parse data rows
            rows.removeFirst() // Remove header
            var contacts: [OperationalContact] = []

            for (rowNum, row) in rows.enumerated() {
                let columns = parseCSVRow(row)
                
                guard columns.count > max(nameIdx, phoneIdx) else {
                    print("Row \(rowNum + 2) has insufficient columns, skipping")
                    continue
                }
                
                let name = columns[nameIdx].trimmingCharacters(in: .whitespacesAndNewlines)
                let phone = columns[phoneIdx].trimmingCharacters(in: .whitespacesAndNewlines)
                
                guard !name.isEmpty && !phone.isEmpty else {
                    print("Row \(rowNum + 2) missing required name or phone, skipping")
                    continue
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

                contacts.append(contact)
            }

            guard !contacts.isEmpty else {
                throw NSError(domain: "", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "No valid contacts found in CSV file."
                ])
            }

            // Add contacts to "Imported" category
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
            let categoryName = "Imported CSV (\(timestamp))"
            
            var categories = ContactsManager.shared.loadCategories()
            ContactsManager.shared.addCategory(name: categoryName, contacts: contacts, to: &categories)

            DispatchQueue.main.async {
                let message = contacts.count == 1
                    ? "1 contact imported from CSV."
                    : "\(contacts.count) contacts imported from CSV."
                
                let alert = UIAlertController(
                    title: "CSV Import Successful",
                    message: message,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
            }

        } catch {
            DispatchQueue.main.async {
                self.showImportError(error: error)
            }
        }
    }
    
    // MARK: - Existing Methods (unchanged)
    private func importChecklist(from url: URL) {
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
        do {
            let content = try String(contentsOf: url)
            var rows = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

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
                let columns = row.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
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
            DispatchQueue.main.async {
                self.showImportError(error: error)
            }
        }
    }
    
    private func showImportConfirmation(for checklist: CustomChecklist) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else { return }
        
        let alert = UIAlertController(
            title: "Import Checklist",
            message: "Do you want to import '\(checklist.title)'?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Import", style: .default) { _ in
            // Add to custom checklists
            CustomChecklistManager.shared.add(checklist)
            
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
    
    private func showImportError(error: Error) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else { return }
        
        let alert = UIAlertController(
            title: "Import Failed",
            message: "Could not import: \(error.localizedDescription)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        rootVC.present(alert, animated: true)
    }
    
    // MARK: - Enhanced Helper Functions
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
