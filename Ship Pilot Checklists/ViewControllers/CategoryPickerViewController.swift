//
//  CategoryPickerViewController.swift
//  Ship Pilot Checklists
//

import UIKit

class CategoryPickerViewController: UIViewController {
    
    // MARK: - Properties
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let categories: [ContactCategory]
    private let onSelection: (Int) -> Void
    
    // MARK: - Initialization
    init(categories: [ContactCategory], onSelection: @escaping (Int) -> Void) {
        self.categories = categories
        self.onSelection = onSelection
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Apply navigation bar theme when view appears
        updateNavigationBarTheme()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateTheme()
        updateNavigationBarTheme()
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Force theme
        overrideUserInterfaceStyle = UserDefaults.standard.bool(forKey: "nightMode") ? .dark : .light
        
        title = "Choose Category"
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        
        setupNavigationBar()
        setupTableView()
        updateTheme()
        updateNavigationBarTheme()
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func updateTheme() {
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        tableView.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        
        // Update navigation bar button color
        let tintColor = ThemeManager.navBarForegroundColor(for: traitCollection)
        navigationItem.leftBarButtonItem?.tintColor = tintColor
        
        // Reload table to update cell colors
        tableView.reloadData()
    }
    
    private func updateNavigationBarTheme() {
        guard let navigationController = navigationController else { return }
        ThemeManager.apply(to: navigationController, traitCollection: traitCollection)
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource
extension CategoryPickerViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let category = categories[indexPath.row]
        
        // Set up cell style to support detail text
        cell.textLabel?.text = category.name
        cell.textLabel?.textColor = ThemeManager.titleColor(for: traitCollection)
        
        // Set cell background color
        cell.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        
        // Show contact count
        let count = category.contacts.count
        if count > 0 {
            // Create a secondary label for the count since detailTextLabel might not work in all styles
            if cell.detailTextLabel != nil {
                cell.detailTextLabel?.text = "\(count) contact\(count == 1 ? "" : "s")"
                cell.detailTextLabel?.textColor = .secondaryLabel
            } else {
                // If no detailTextLabel, add count to main text
                cell.textLabel?.text = "\(category.name) (\(count) contact\(count == 1 ? "" : "s"))"
            }
        } else {
            if cell.detailTextLabel != nil {
                cell.detailTextLabel?.text = "No contacts"
                cell.detailTextLabel?.textColor = .secondaryLabel
            } else {
                cell.textLabel?.text = "\(category.name) (No contacts)"
            }
        }
        
        // Set selection style
        cell.selectionStyle = .default
        cell.accessoryType = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Select a category for this contact"
    }
}

// MARK: - UITableViewDelegate
extension CategoryPickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Dismiss and call completion
        dismiss(animated: true) { [weak self] in
            self?.onSelection(indexPath.row)
        }
    }
}
