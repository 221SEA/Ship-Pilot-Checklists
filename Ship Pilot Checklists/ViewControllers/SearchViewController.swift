//
//  SearchViewController.swift
//  Ship Pilot Checklists
//

import UIKit

/// A single search result can be either an included (built-in) checklist
/// or one of the user's custom checklists.
private enum SearchResult {
    case builtIn(ChecklistInfo)
    case custom(CustomChecklist)
    
    /// The title to display in the search results list.
    var title: String {
        switch self {
        case .builtIn(let info):  return info.title
        case .custom(let custom): return custom.title
        }
    }
    
    /// Returns a subtitle indicating the type of checklist
    var subtitle: String {
        switch self {
        case .builtIn(_): return "Included Checklist"
        case .custom(_): return "Custom Checklist"
        }
    }
    /// Returns true if this checklist contains the search term in its title or any item
    func matches(searchTerm: String) -> Bool {
        let lower = searchTerm.lowercased()
        
        // Check title first
        if title.lowercased().contains(lower) {
            return true
        }
        
        // Check all items in all sections
        switch self {
        case .builtIn(let info):
            for section in info.sections {
                for item in section.items {
                    if item.title.lowercased().contains(lower) {
                        return true
                    }
                }
            }
            
        case .custom(let custom):
            for section in custom.sections {
                for item in section.items {
                    if item.title.lowercased().contains(lower) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    /// Instantiates and pushes the appropriate ChecklistViewController onto
    /// the given navigation controller.
    func showDetail(on nav: UINavigationController) {
        switch self {
        case .builtIn(let info):
            let detailVC = ChecklistViewController()
            detailVC.checklist = info
            nav.pushViewController(detailVC, animated: true)
            
        case .custom(let custom):
            let detailVC = ChecklistViewController()
            detailVC.customChecklist = custom
            nav.pushViewController(detailVC, animated: true)
        }
    }
}

class SearchViewController: UIViewController {
    
    // MARK: — UI Subviews
    
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.translatesAutoresizingMaskIntoConstraints = false
        sb.placeholder = "Search Checklists"
        sb.showsCancelButton = true
        sb.searchBarStyle = .minimal
        return sb
    }()
    
    private let resultsTableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        
        tv.keyboardDismissMode = .onDrag
        return tv
    }()
    
    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Search all included and custom checklists"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        return label
    }()
    
    // MARK: — Data Storage
    
    /// All checklists (built-in + custom)
    private var allResults: [SearchResult] = []
    
    /// The filtered subset matching the current search text
    private var filteredResults: [SearchResult] = []
    
    
    // MARK: — Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        loadAllChecklists()
        
        searchBar.delegate = self
        resultsTableView.dataSource = self
        resultsTableView.delegate = self
        
        // Start with empty search (show instruction)
        updateSearchResults(with: "")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide any bottom toolbar
        navigationController?.setToolbarHidden(true, animated: false)
        
        // Reload data in case custom checklists changed
        loadAllChecklists()
        updateSearchResults(with: searchBar.text ?? "")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Auto-focus the search bar
        searchBar.becomeFirstResponder()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateAppearanceForTraitCollection()
    }
    
    
    // MARK: — UI Setup
    
    private func configureUI() {
        // 1) Navigation setup
        title = "Search"
        navigationItem.largeTitleDisplayMode = .never
        
        // Add cancel button to navigation
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        // 2) Apply background color from ThemeManager
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        
        // 3) Add subviews
        view.addSubview(searchBar)
        view.addSubview(resultsTableView)
        view.addSubview(instructionLabel)
        
        NSLayoutConstraint.activate([
            // Position searchBar at the very top under the safe area
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // resultsTableView fills the rest of the screen
            resultsTableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            resultsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            resultsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            resultsTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Instruction label centered
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            instructionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
        
        // 4) Initial appearance setup
        updateAppearanceForTraitCollection()
    }
    
    private func updateAppearanceForTraitCollection() {
        // Backgrounds
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        resultsTableView.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        
        // Navigation bar button
        navigationItem.rightBarButtonItem?.tintColor = ThemeManager.titleColor(for: traitCollection)
        
        // Search-bar style
        if traitCollection.userInterfaceStyle == .dark {
            searchBar.barStyle = .black
            searchBar.keyboardAppearance = .dark
        } else {
            searchBar.barStyle = .default
            searchBar.keyboardAppearance = .light
        }
        
        // Update text colors
        instructionLabel.textColor = .secondaryLabel
        
        // Reload table so its cells pick up the new colors
        resultsTableView.reloadData()
    }
    
    @objc private func cancelTapped() {
        searchBar.resignFirstResponder()
        dismiss(animated: true)
    }
    
    
    // MARK: — Data Loading
    
    private func loadAllChecklists() {
        var combined: [SearchResult] = []
        
        // 1) Load all built-in checklists from IncludedChecklists.all
        let builtIns: [ChecklistInfo] = IncludedChecklists.all
        for info in builtIns {
            combined.append(.builtIn(info))
        }
        
        // 2) Load all custom checklists from CustomChecklistManager
        let customs = CustomChecklistManager.shared.loadAll()
        for custom in customs {
            combined.append(.custom(custom))
        }
        
        // 3) Sort alphabetically
        combined.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        
        allResults = combined
    }
    
    
    // MARK: — Filtering Logic
    
    private func updateSearchResults(with searchText: String) {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            filteredResults = []
            instructionLabel.isHidden = false
            instructionLabel.text = "Search \(allResults.count) checklists (\(allResults.filter { if case .builtIn = $0 { return true }; return false }.count) included, \(allResults.filter { if case .custom = $0 { return true }; return false }.count) custom)"
        } else {
            // Use the new matches method that searches both titles and items
            filteredResults = allResults.filter { result in
                result.matches(searchTerm: trimmed)
            }
            
            // Update instruction label to show if no results
            if filteredResults.isEmpty {
                instructionLabel.isHidden = false
                instructionLabel.text = "No checklists found containing '\(trimmed)'"
            } else {
                instructionLabel.isHidden = true
            }
        }
        
        resultsTableView.reloadData()
    }
}


// MARK: — UISearchBarDelegate

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateSearchResults(with: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        dismiss(animated: true)
    }
}


// MARK: — UITableViewDataSource

extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredResults.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "SearchResultCell")
        let result = filteredResults[indexPath.row]
        
        // Configure cell with title
        cell.textLabel?.text = result.title
        cell.accessoryType = .disclosureIndicator
        
        // Show subtitle - either the type or which item matched
        if let searchText = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines), !searchText.isEmpty {
            let lower = searchText.lowercased()
            
            // Check if title matches
            if result.title.lowercased().contains(lower) {
                cell.detailTextLabel?.text = result.subtitle
            } else {
                // Find which item matched
                var matchedItem: String?
                
                switch result {
                case .builtIn(let info):
                    for section in info.sections {
                        for item in section.items {
                            if item.title.lowercased().contains(lower) {
                                matchedItem = item.title
                                break
                            }
                        }
                        if matchedItem != nil { break }
                    }
                    
                case .custom(let custom):
                    for section in custom.sections {
                        for item in section.items {
                            if item.title.lowercased().contains(lower) {
                                matchedItem = item.title
                                break
                            }
                        }
                        if matchedItem != nil { break }
                    }
                }
                
                if let matched = matchedItem {
                    cell.detailTextLabel?.text = "Contains: \(matched)"
                } else {
                    cell.detailTextLabel?.text = result.subtitle
                }
            }
        } else {
            cell.detailTextLabel?.text = result.subtitle
        }
        
        // Apply theming
        cell.textLabel?.textColor = ThemeManager.titleColor(for: traitCollection)
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        
        return cell
    }
}


// MARK: — UITableViewDelegate

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let chosen = filteredResults[indexPath.row]
        
        // Dismiss keyboard first
        searchBar.resignFirstResponder()
        
        // Get the main navigation controller
        guard let presentingNav = presentingViewController as? UINavigationController else {
            // Fallback: push on the search's own nav
            if let searchNav = self.navigationController {
                chosen.showDetail(on: searchNav)
            }
            return
        }
        
        // Dismiss the search modal, then push onto the main nav
        dismiss(animated: true) {
            chosen.showDetail(on: presentingNav)
        }
    }
}
