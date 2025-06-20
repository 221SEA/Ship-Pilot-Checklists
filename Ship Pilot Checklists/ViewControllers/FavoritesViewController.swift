//
//  FavoritesViewController.swift
//  Ship Pilot Checklists
//
//  This is the complete and final version.
//

import UIKit

// MARK: - Models (These are fine)
struct FavoriteEntry: Codable {
    let id: String
    let isCustom: Bool
}

struct FavoriteCategory: Codable {
    var name: String
    var entries: [FavoriteEntry]
}

// MARK: - FavoritesViewController
class FavoritesViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var categories: [FavoriteCategory] = []
    private let defaultsKey = "FavoritesCategories"

    // MARK: – Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = [.all]
        extendedLayoutIncludesOpaqueBars = true
        overrideUserInterfaceStyle = UserDefaults.standard.bool(forKey: "nightMode") ? .dark : .light
        title = "Favorites"
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        setupHeader()
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.setNeedsLayout()
        loadCategories() // Reload data in case favorites changed
        tableView.reloadData()
    }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        ThemeManager.apply(to: navigationController, traitCollection: traitCollection)
        tableView.reloadData()
    }

    // MARK: – Setup
    private func setupHeader() {
        let header = UIView()
        header.backgroundColor = .clear

        let btn = UIButton(type: .system)
        btn.setTitle("Add Category +", for: .normal)
        btn.backgroundColor = ThemeManager.themeColor
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        btn.layer.cornerRadius = 8
        btn.contentEdgeInsets = .init(top:12, left:16, bottom:12, right:16)
        btn.addTarget(self, action: #selector(addCategoryTapped), for: .touchUpInside)

        header.addSubview(btn)
        btn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            btn.topAnchor.constraint(equalTo: header.topAnchor, constant: 8),
            btn.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            btn.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            btn.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -8)
        ])

        let h = btn.intrinsicContentSize.height + 16
        header.frame = CGRect(x:0, y:0, width:view.bounds.width, height:h)
        tableView.tableHeaderView = header
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true
        
        // UPDATED: Register our new custom FavoriteCell
        tableView.register(FavoriteCell.self, forCellReuseIdentifier: "FavoriteCell")

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: – Persistence & Actions
    private func loadCategories() {
        // First, load user-created categories from UserDefaults
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let saved = try? JSONDecoder().decode([FavoriteCategory].self, from: data) {
            categories = saved
        }
        
        // If there are no saved categories, create a default "Favorites" category.
        if categories.isEmpty {
            categories.append(FavoriteCategory(name: "Favorites", entries: []))
        }

        // --- Get all favorited checklists using our new managers ---
        let favoritedBuiltInTitles = FavoritesManager.getFavoritedTitles()
        let favoritedCustom = CustomChecklistManager.shared.loadAll().filter { $0.isFavorite }
        
        let builtInEntries = favoritedBuiltInTitles.map { FavoriteEntry(id: $0, isCustom: false) }
        let customEntries = favoritedCustom.map { FavoriteEntry(id: $0.id.uuidString, isCustom: true) }

        // Place all favorites into the first category, clearing out old entries first
        if !categories.isEmpty {
            categories[0].name = "Favorites"
            categories[0].entries = builtInEntries + customEntries
        }
        
        // Remove any other categories that might now be empty
        categories.removeAll { $0.entries.isEmpty && $0.name != "Favorites" }
    }
    
    private func saveCategories() {
        if let data = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
    
    @objc private func addCategoryTapped() {
        let ac = UIAlertController(title: "New Category",
                                     message: "Enter a name",
                                     preferredStyle: .alert)
        ac.addTextField { $0.placeholder = "Category Name" }
        ac.addAction(.init(title: "Cancel", style: .cancel))
        ac.addAction(.init(title: "Add", style: .default) { _ in
            guard let name = ac.textFields?.first?.text?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else { return }
            self.categories.append(FavoriteCategory(name: name, entries: []))
            self.saveCategories()
            self.tableView.reloadData()
        })
        present(ac, animated: true)
    }
    
    @objc private func unfavoriteTapped(_ sender: UIButton) {
        let section = sender.tag >> 16
        let row = sender.tag & 0xFFFF
        let entry = categories[section].entries[row]

        if entry.isCustom {
            if var cc = CustomChecklistManager.shared.loadAll().first(where: { $0.id.uuidString == entry.id }) {
                cc.isFavorite = false
                CustomChecklistManager.shared.update(cc)
            }
        } else {
            FavoritesManager.toggleFavorite(for: entry.id)
        }
        
        // Reload data and table to reflect the change
        loadCategories()
        tableView.reloadData()
    }
}

// MARK: – UITableViewDataSource
extension FavoritesViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { return categories.count }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { return categories[section].name }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return categories[section].entries.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteCell", for: indexPath) as! FavoriteCell
        
        let entry = categories[indexPath.section].entries[indexPath.row]
        var titleText: String?

        if entry.isCustom {
            titleText = CustomChecklistManager.shared.loadAll().first(where: { $0.id.uuidString == entry.id })?.title
        } else {
            titleText = IncludedChecklists.all.first(where: { $0.title == entry.id })?.title
        }
        
        let isNight = (self.traitCollection.userInterfaceStyle == .dark)
        cell.configure(with: titleText, isNightMode: isNight)
        
        cell.starButton.tag = (indexPath.section << 16) | indexPath.row
        cell.starButton.addTarget(self, action: #selector(unfavoriteTapped(_:)), for: .touchUpInside)

        return cell
    }
}

// MARK: – UITableViewDelegate and Drag & Drop
extension FavoritesViewController: UITableViewDelegate, UITableViewDragDelegate, UITableViewDropDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let entry = categories[indexPath.section].entries[indexPath.row]
        let vc = ChecklistViewController()

        if entry.isCustom {
            if let cc = CustomChecklistManager.shared.loadAll().first(where: { $0.id.uuidString == entry.id }) {
                vc.customChecklist = cc
                navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            if let ci = IncludedChecklists.all.first(where: { $0.title == entry.id }) {
                vc.checklist = ci
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let entry = categories[indexPath.section].entries[indexPath.row]
        let provider = NSItemProvider(object: "\(indexPath.section),\(indexPath.row)" as NSString)
        let dragItem = UIDragItem(itemProvider: provider)
        dragItem.localObject = (indexPath.section, indexPath.row, entry)
        return [dragItem]
    }

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath dest: IndexPath?) -> UITableViewDropProposal {
        return .init(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        guard let drop = coordinator.items.first,
              let (srcSec, srcRow, entry) = drop.dragItem.localObject as? (Int, Int, FavoriteEntry),
              let dest = coordinator.destinationIndexPath else { return }

        let originalSourceIndexPath = IndexPath(row: srcRow, section: srcSec)
        
        tableView.beginUpdates()
        
        categories[originalSourceIndexPath.section].entries.remove(at: originalSourceIndexPath.row)
        tableView.deleteRows(at: [originalSourceIndexPath], with: .fade)
        
        categories[dest.section].entries.insert(entry, at: dest.row)
        tableView.insertRows(at: [dest], with: .fade)
        
        tableView.endUpdates()
        
        saveCategories()
    }
}
