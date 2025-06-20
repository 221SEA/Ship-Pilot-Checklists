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
        
        // Check if this is a .shipchecklist file
        guard url.pathExtension.lowercased() == "shipchecklist" else { return }
        
        // Import the checklist
        importChecklist(from: url)
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
