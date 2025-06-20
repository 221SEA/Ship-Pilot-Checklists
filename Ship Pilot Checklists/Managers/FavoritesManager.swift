//
//  FavoritesManager.swift
//  Ship Pilot Checklists
//

import Foundation

struct FavoritesManager {
    
    // The key where we'll store the titles of our favorited built-in checklists
    private static let key = "BuiltInFavorites"
    
    /// Returns a Set of all favorited checklist titles for quick lookups
    static func getFavoritedTitles() -> Set<String> {
        let array = UserDefaults.standard.array(forKey: key) as? [String] ?? []
        return Set(array)
    }
    
    /// Saves the current set of favorited titles to UserDefaults
    static func save(favoritedTitles: Set<String>) {
        let array = Array(favoritedTitles)
        UserDefaults.standard.set(array, forKey: key)
    }
    
    /// Toggles a checklist's favorite status
    static func toggleFavorite(for checklistTitle: String) {
        var favorites = getFavoritedTitles()
        if favorites.contains(checklistTitle) {
            favorites.remove(checklistTitle)
        } else {
            favorites.insert(checklistTitle)
        }
        save(favoritedTitles: favorites)
    }
    
    /// Checks if a specific checklist is a favorite
    static func isFavorite(checklistTitle: String) -> Bool {
        return getFavoritedTitles().contains(checklistTitle)
    }
}
