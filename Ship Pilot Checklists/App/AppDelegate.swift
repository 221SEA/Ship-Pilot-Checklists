//
//  AppDelegate.swift
//  Ship Pilot Checklists
//

import UIKit
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        print("AppDelegate - didFinishLaunchingWithOptions called")
        
        // REMOVED: Don't delete contacts data anymore!
        // UserDefaults.standard.removeObject(forKey: "OperationalContactCategories")
        
        // Initialize ContactsManager to trigger migration if needed
        _ = ContactsManager.shared.loadCategories()

        ThemeManager.applyToCurrentWindow()

        return true
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication,
                     didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}

    // MARK: - App Lifecycle for Contact Persistence
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Force save contacts when app goes to background
        let categories = ContactsManager.shared.loadCategories()
        ContactsManager.shared.saveCategories(categories)
        
        // Create manual backup for extra safety
        _ = ContactsManager.shared.createManualBackup()
        
        // Existing Core Data save
        saveContext()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Ensure contacts are saved before app terminates
        let categories = ContactsManager.shared.loadCategories()
        ContactsManager.shared.saveCategories(categories)
        
        // Existing Core Data save
        saveContext()
    }

    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Ship_Pilot_Checklists")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
