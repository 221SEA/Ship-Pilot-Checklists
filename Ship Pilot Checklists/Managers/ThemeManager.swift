import UIKit

struct ThemeManager {
    static let themeColor = UIColor(red: 41/255, green: 97/255, blue: 142/255, alpha: 1)
    static let lightBackground = UIColor(hex: 0xF1F4F7)
    static let darkBackground = UIColor.black
    static let darkTitle = UIColor.green
    
    // MARK: - Colors
    
    static func backgroundColor(for trait: UITraitCollection) -> UIColor {
        trait.userInterfaceStyle == .dark ? darkBackground : lightBackground
    }
    
    static func titleColor(for trait: UITraitCollection) -> UIColor {
        trait.userInterfaceStyle == .dark ? darkTitle : themeColor
    }
    
    static func navBarColor(for trait: UITraitCollection) -> UIColor {
        trait.userInterfaceStyle == .dark ? darkBackground : themeColor
    }
    
    static func navBarForegroundColor(for trait: UITraitCollection) -> UIColor {
        trait.userInterfaceStyle == .dark ? darkTitle : .white
    }
    
    // MARK: - Appearance
    
    static func navBarAppearance(for trait: UITraitCollection) -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = navBarColor(for: trait)
        appearance.shadowColor = .clear
        
        let fg = navBarForegroundColor(for: trait)
        appearance.titleTextAttributes = [.foregroundColor: fg]
        appearance.largeTitleTextAttributes = [.foregroundColor: fg]
        return appearance
    }
    
    static func apply(to navigationController: UINavigationController?, traitCollection: UITraitCollection) {
        let appearance = navBarAppearance(for: traitCollection)
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.compactScrollEdgeAppearance = appearance
        
        // Tint affects UIBarButtonItems (Back, Edit, Add, etc.)
        let tint = navBarForegroundColor(for: traitCollection)
        navigationController?.navigationBar.tintColor = tint
        navigationController?.navigationBar.layoutIfNeeded()
        
        // This updates any UIBarButtonItems globally
        UIBarButtonItem.appearance().tintColor = tint
    }
    
    /// Apply theme to the app's root navigation controller
    static func applyToCurrentWindow() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }
        applyRecursively(to: rootVC)
    }
    static func applyToolbarAppearance(_ toolbar: UIToolbar, trait: UITraitCollection) {
        let bgColor = navBarColor(for: trait)
        let fgColor = navBarForegroundColor(for: trait)
        
        toolbar.barTintColor = bgColor
        toolbar.tintColor = fgColor
        toolbar.isTranslucent = false
        toolbar.backgroundColor = bgColor
        
        if #available(iOS 13.0, *) {
            let appearance = UIToolbarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = bgColor
            appearance.shadowColor = .clear
            
            // Set button title text color (fixes "dull white" issue)
            appearance.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: fgColor]
            
            toolbar.standardAppearance = appearance
            
            if #available(iOS 15.0, *) {
                toolbar.scrollEdgeAppearance = appearance
            }
        }
    }
    
    private static func applyRecursively(to viewController: UIViewController) {
        if let navController = viewController as? UINavigationController {
            apply(to: navController, traitCollection: navController.traitCollection)
            for child in navController.viewControllers {
                applyRecursively(to: child)
            }
        } else {
            for child in viewController.children {
                applyRecursively(to: child)
            }
            
        }
    }
}

