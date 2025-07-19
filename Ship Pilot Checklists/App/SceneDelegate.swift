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
            importChecklistFromCSV(url: url)
        case "shipcontacts":
            importContacts(from: url)
        default:
            break
        }
    }
    private func importContacts(from url: URL) {
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
                let alert = UIAlertController(
                    title: "Contacts Imported",
                    message: "Contact list successfully imported.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
            }

        } catch {
            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: "Import Failed",
                    message: "Unable to read contact data: \(error.localizedDescription)",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
            }
        }
    }
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
            message: "Could not import checklist: \(error.localizedDescription)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        rootVC.present(alert, animated: true)
    }
    
    
    func sceneDidDisconnect(_ scene: UIScene) { }
    func sceneDidBecomeActive(_ scene: UIScene) { }
    func sceneWillResignActive(_ scene: UIScene) { }
    func sceneWillEnterForeground(_ scene: UIScene) { }
    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
    
}
