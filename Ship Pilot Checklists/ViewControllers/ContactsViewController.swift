//
//  ContactsViewController.swift
//  Ship Pilot Checklists
//

import UIKit
import MessageUI

class ContactsViewController: UIViewController {
    
    // MARK: - Properties
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let searchController = UISearchController(searchResultsController: nil)
    private var categories: [ContactCategory] = []
    private var filteredContacts: [(contact: OperationalContact, category: String)] = []
    private var isSearching: Bool {
        return searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true)
    }
    
    // NEW: Flag to open directly to Emergency category
    var openToEmergencyCategory = false  // ← PUT IT HERE, OUTSIDE of isSearching
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: false)
        
        // Force the navigation bar to update its appearance
        navigationController?.navigationBar.setNeedsLayout()
        navigationController?.navigationBar.layoutIfNeeded()
        
        // Reload in case contacts were edited
        loadData()
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // If we should open to Emergency category
        if openToEmergencyCategory {
            openToEmergencyCategory = false // Reset flag
            
            // Find Emergency category index
            if let emergencyIndex = categories.firstIndex(where: { $0.name == "Emergency" }) {
                // Scroll to Emergency section
                let indexPath = IndexPath(row: 0, section: emergencyIndex)
                if categories[emergencyIndex].contacts.isEmpty {
                    // If no contacts, prompt to add one
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.addContactToCategory(at: emergencyIndex)
                    }
                } else {
                    // Scroll to show the Emergency section
                    tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                }
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateTheme()
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Force theme
        overrideUserInterfaceStyle = UserDefaults.standard.bool(forKey: "nightMode") ? .dark : .light
        
        title = "Contacts"
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        
        setupNavigationBar()
        setupSearchController()
        setupTableView()
        updateTheme()
    }
    
    private func setupNavigationBar() {
        // Add button in navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addContactTapped)
        )
        
        // Force white color for nav bar buttons in light mode
        if traitCollection.userInterfaceStyle == .light {
            navigationItem.rightBarButtonItem?.tintColor = .white
        }
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search contacts..."
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        // ADD THIS to fix search bar text colors:
        // Search field text
        searchController.searchBar.searchTextField.textColor = .label
        
        // For the search bar itself in the navigation bar
        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            textField.textColor = .label
            textField.tintColor = ThemeManager.themeColor
            
            // Placeholder text
            textField.attributedPlaceholder = NSAttributedString(
                string: "Search contacts...",
                attributes: [.foregroundColor: UIColor.secondaryLabel]
            )
        }
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true
        
        // Register cells
        tableView.register(ContactCell.self, forCellReuseIdentifier: "ContactCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        // Setup header with Add Category button
        setupTableHeader()
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupTableHeader() {
        let header = UIView()
        header.backgroundColor = .clear
        
        let button = UIButton(type: .system)
        button.setTitle("Add Category +", for: .normal)
        button.backgroundColor = ThemeManager.themeColor
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        button.addTarget(self, action: #selector(addCategoryTapped), for: .touchUpInside)
        
        header.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: header.topAnchor, constant: 8),
            button.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            button.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -8)
        ])
        
        let height = button.intrinsicContentSize.height + 16
        header.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: height)
        tableView.tableHeaderView = header
    }
    
    private func updateTheme() {
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        tableView.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        
        // Fix nav bar button colors
        if traitCollection.userInterfaceStyle == .light {
            navigationItem.rightBarButtonItem?.tintColor = .white
        } else {
            navigationItem.rightBarButtonItem?.tintColor = ThemeManager.titleColor(for: traitCollection)
        }
        
        // Update search bar appearance
        if traitCollection.userInterfaceStyle == .dark {
            searchController.searchBar.barStyle = .black
            searchController.searchBar.tintColor = .white  // Cancel button
        } else {
            searchController.searchBar.barStyle = .default
            searchController.searchBar.tintColor = .white  // Cancel button
        }
        
        // Update search field colors
        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            textField.textColor = .label
            textField.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        }
    }
    
    // MARK: - Data
    private func loadData() {
        categories = ContactsManager.shared.loadCategories()
    }
    
    // MARK: - Actions
    @objc private func addCategoryTapped() {
        let alert = UIAlertController(
            title: "New Category",
            message: "Enter a name for the new category",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Category Name"
            textField.autocapitalizationType = .words
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self,
                  let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else { return }
            
            ContactsManager.shared.addCategory(name: name, to: &self.categories)
            self.tableView.reloadData()
        })
        
        present(alert, animated: true)
    }
    
    @objc private func addContactTapped() {
        // Show category picker first
        let categoryPicker = CategoryPickerViewController(categories: categories) { [weak self] categoryIndex in
            guard let self = self else { return }
            let editor = ContactEditorViewController(mode: .add(categoryIndex: categoryIndex))
            editor.delegate = self
            let nav = UINavigationController(rootViewController: editor)
            self.present(nav, animated: true)
        }
        
        let nav = UINavigationController(rootViewController: categoryPicker)
        present(nav, animated: true)
    }
    private func addContactToCategory(at categoryIndex: Int) {
        let editor = ContactEditorViewController(mode: .add(categoryIndex: categoryIndex))
        editor.delegate = self
        let nav = UINavigationController(rootViewController: editor)
        present(nav, animated: true)
    }
    
    private func callContact(_ contact: OperationalContact) {
        // Update last used
        ContactsManager.shared.updateLastUsed(for: contact.id, in: &categories)
        
        // Clean phone number and make call
        let cleanedPhone = contact.phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel://\(cleanedPhone)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func textContact(_ contact: OperationalContact) {
        guard MFMessageComposeViewController.canSendText() else {
            showAlert(title: "Cannot Send Message", message: "Your device cannot send SMS messages.")
            return
        }
        
        // Update last used
        ContactsManager.shared.updateLastUsed(for: contact.id, in: &categories)
        
        let composer = MFMessageComposeViewController()
        composer.messageComposeDelegate = self
        composer.recipients = [contact.phone]
        present(composer, animated: true)
    }
    
    private func showContactOptions(for contact: OperationalContact, at indexPath: IndexPath) {
        let actionSheet = UIAlertController(title: contact.name, message: contact.role, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Call", style: .default) { [weak self] _ in
            self?.callContact(contact)
        })
        
        actionSheet.addAction(UIAlertAction(title: "Text", style: .default) { [weak self] _ in
            self?.textContact(contact)
        })
        
        actionSheet.addAction(UIAlertAction(title: "View / Edit", style: .default) { [weak self] _ in
            let editor = ContactEditorViewController(mode: .edit(contact: contact, indexPath: indexPath))
            editor.delegate = self
            let nav = UINavigationController(rootViewController: editor)
            self?.present(nav, animated: true)
        })
        
        actionSheet.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.confirmDelete(at: indexPath)
        })
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // iPad support
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = tableView.rectForRow(at: indexPath)
        }
        
        present(actionSheet, animated: true)
    }
    
    private func confirmDelete(at indexPath: IndexPath) {
        let contact = categories[indexPath.section].contacts[indexPath.row]
        
        let alert = UIAlertController(
            title: "Delete Contact",
            message: "Delete \(contact.name)?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            ContactsManager.shared.deleteContact(at: indexPath, from: &self.categories)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        })
        
        present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension ContactsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return isSearching ? 1 : categories.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            return filteredContacts.count
        }
        return categories[section].contacts.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isSearching {
            return "Search Results"
        }
        return categories[section].name
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isSearching {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! ContactCell
            let result = filteredContacts[indexPath.row]
            cell.configure(with: result.contact, category: result.category, traitCollection: traitCollection)
            cell.callAction = { [weak self] in
                self?.callContact(result.contact)
            }
            cell.textAction = { [weak self] in
                self?.textContact(result.contact)
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! ContactCell
            let contact = categories[indexPath.section].contacts[indexPath.row]
            cell.configure(with: contact, category: nil, traitCollection: traitCollection)
            cell.callAction = { [weak self] in
                self?.callContact(contact)
            }
            cell.textAction = { [weak self] in
                self?.textContact(contact)
            }
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension ContactsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if isSearching {
            let result = filteredContacts[indexPath.row]
            // Find the actual indexPath for this contact
            for (sectionIndex, category) in categories.enumerated() {
                if let rowIndex = category.contacts.firstIndex(where: { $0.id == result.contact.id }) {
                    let actualIndexPath = IndexPath(row: rowIndex, section: sectionIndex)
                    showContactOptions(for: result.contact, at: actualIndexPath)
                    break
                }
            }
        } else {
            let contact = categories[indexPath.section].contacts[indexPath.row]
            showContactOptions(for: contact, at: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !isSearching else { return nil }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.confirmDelete(at: indexPath)
            completion(true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - Drag & Drop
extension ContactsViewController: UITableViewDragDelegate, UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard !isSearching else { return [] }
        
        let contact = categories[indexPath.section].contacts[indexPath.row]
        let provider = NSItemProvider(object: contact.id.uuidString as NSString)
        let dragItem = UIDragItem(itemProvider: provider)
        dragItem.localObject = (contact, indexPath)
        return [dragItem]
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        guard let item = coordinator.items.first,
              let (_, sourceIndexPath) = item.dragItem.localObject as? (OperationalContact, IndexPath),
              let destinationIndexPath = coordinator.destinationIndexPath else { return }
        
        tableView.performBatchUpdates({
            ContactsManager.shared.moveContact(from: sourceIndexPath, to: destinationIndexPath, in: &categories)
            tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
        })
    }
}

// MARK: - UISearchResultsUpdating
extension ContactsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text, !query.isEmpty else {
            filteredContacts = []
            tableView.reloadData()
            return
        }
        
        filteredContacts = ContactsManager.shared.searchContacts(in: categories, query: query)
        tableView.reloadData()
    }
}

// MARK: - MFMessageComposeViewControllerDelegate
extension ContactsViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
    }
}

// MARK: - ContactEditorDelegate
extension ContactsViewController: ContactEditorDelegate {
    func contactEditor(_ editor: ContactEditorViewController, didSave contact: OperationalContact, mode: ContactEditorMode) {
        switch mode {
        case .add(let categoryIndex):
            ContactsManager.shared.addContact(contact, to: categoryIndex, in: &categories)
        case .edit(_, let indexPath):
            ContactsManager.shared.updateContact(contact, at: indexPath, in: &categories)
        }
        tableView.reloadData()
    }
}
