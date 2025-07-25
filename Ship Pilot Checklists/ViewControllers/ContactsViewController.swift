//
//  ContactsViewController.swift
//  Ship Pilot Checklists
//

import UIKit
import MessageUI
import ContactsUI

class ContactsViewController: UIViewController, CNContactPickerDelegate {
    
    // MARK: - Properties
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let searchController = UISearchController(searchResultsController: nil)
    private let bottomToolbar = UIToolbar()
    private var categories: [ContactCategory] = []
    private var filteredContacts: [(contact: OperationalContact, category: String)] = []
    private var isSearching: Bool {
        return searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true)
        
    }
    private var expandedSections = Set<Int>()
    
    // NEW: Flag to open directly to Emergency category
    var openToEmergencyCategory = false
    var returnToChecklist: (() -> Void)?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupToolbar()
        loadData()
        
        // Expand all sections by default
        for i in 0..<categories.count {
            expandedSections.insert(i)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: false)
        
        // Force the navigation bar to update its appearance
        navigationController?.navigationBar.setNeedsLayout()
        navigationController?.navigationBar.layoutIfNeeded()
        
        // Force search bar to update its appearance
        if let searchBar = navigationController?.navigationBar.subviews.first(where: { $0 is UISearchBar }) as? UISearchBar {
            searchBar.setNeedsLayout()
            searchBar.layoutIfNeeded()
        }
        
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
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if tableView.tableHeaderView == nil {
            setupTableHeader()
        }

        ThemeManager.applyToolbarAppearance(bottomToolbar, trait: traitCollection)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateTheme()
        setupToolbar()
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
        setupToolbar()
        updateTheme()
    }
    
    private func setupTableHeader() {
        // Optional: implement a custom header if needed in the future
    }
    
    private func setupNavigationBar() {
        // Right side: manual add
        navigationItem.rightBarButtonItem = nil
        navigationItem.leftBarButtonItem = nil
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search contacts..."
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        // Fix search bar appearance for both light and dark modes
        let searchBar = searchController.searchBar
        
        // Set the search bar style
        if traitCollection.userInterfaceStyle == .light {
            searchBar.barStyle = .default
            searchBar.searchTextField.backgroundColor = .white
            searchBar.tintColor = .white  // This affects the cancel button
        } else {
            searchBar.barStyle = .black
            searchBar.searchTextField.backgroundColor = UIColor.systemGray6
            searchBar.tintColor = ThemeManager.darkTitle  // Green cancel button in dark mode
        }
        
        // Set text field colors using ThemeManager
        let searchTextField = searchBar.searchTextField
        if traitCollection.userInterfaceStyle == .light {
            searchTextField.textColor = .black  // Black text on white background in light mode
        } else {
            searchTextField.textColor = ThemeManager.darkTitle  // Green text in dark mode
        }
        
        // Set placeholder with proper color
        searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Search contacts...",
            attributes: [.foregroundColor: UIColor.placeholderText]
        )
        
        // Fix the magnifying glass icon color
        if let leftView = searchTextField.leftView as? UIImageView {
            leftView.tintColor = .secondaryLabel
        }
        
        // Fix the clear button color
        if let clearButton = searchTextField.value(forKey: "_clearButton") as? UIButton {
            clearButton.tintColor = .secondaryLabel
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
        
        // Remove setupTableHeader() from here - we'll call it later
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    private func setupToolbar() {
        bottomToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomToolbar)

        ThemeManager.applyToolbarAppearance(bottomToolbar, trait: traitCollection)

        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        bottomToolbar.items = [
            toolbarButton(title: "Batch\nImport", action: #selector(importContactsTapped)),
            flexible,
            toolbarButton(title: "Batch\nExport", action: #selector(exportAllContactsTapped)),
            flexible,
            toolbarButton(title: "Add Single\nContact", action: #selector(addContactTapped)),
            flexible,
            toolbarButton(title: "Add\nCategory", action: #selector(addCategoryTapped))
        ]

        NSLayoutConstraint.activate([
            bottomToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomToolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
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
        let searchBar = searchController.searchBar
        
        if traitCollection.userInterfaceStyle == .light {
            searchBar.barStyle = .default
            searchBar.searchTextField.backgroundColor = .white
            searchBar.tintColor = .white  // Cancel button
            
            // For light mode with dark nav bar, we need black text on white background
            searchBar.searchTextField.textColor = .black
        } else {
            searchBar.barStyle = .black
            searchBar.searchTextField.backgroundColor = UIColor.systemGray6
            searchBar.tintColor = ThemeManager.darkTitle  // Green cancel button
            searchBar.searchTextField.textColor = ThemeManager.darkTitle  // Green text in dark mode
        }
        
        // Update placeholder
        searchBar.searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Search contacts...",
            attributes: [.foregroundColor: UIColor.placeholderText]
        )
        
        // Fix icons
        if let leftView = searchBar.searchTextField.leftView as? UIImageView {
            leftView.tintColor = .secondaryLabel
        }
    }
    
    // MARK: - Data
    // Update the loadData method to reset expanded sections:
    private func loadData() {
        categories = ContactsManager.shared.loadCategories()
        
        // Reset expanded sections when data is reloaded
        expandedSections.removeAll()
        for i in 0..<categories.count {
            expandedSections.insert(i)
        }
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
            
            // Apply theme to the navigation controller
            nav.overrideUserInterfaceStyle = UserDefaults.standard.bool(forKey: "nightMode") ? .dark : .light
            ThemeManager.apply(to: nav, traitCollection: nav.traitCollection)
            
            self.present(nav, animated: true)
        }
        
        let nav = UINavigationController(rootViewController: categoryPicker)
        
        // Apply theme to the navigation controller
        nav.overrideUserInterfaceStyle = UserDefaults.standard.bool(forKey: "nightMode") ? .dark : .light
        ThemeManager.apply(to: nav, traitCollection: nav.traitCollection)
        
        present(nav, animated: true)
    }
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        let imported: [OperationalContact] = contacts.compactMap { contact in
            guard let number = contact.phoneNumbers.first?.value.stringValue else { return nil }

            var newContact = OperationalContact(name: "\(contact.givenName) \(contact.familyName)", phone: number)
            newContact.email = contact.emailAddresses.first.map { String($0.value) }
            newContact.organization = contact.organizationName.isEmpty ? nil : contact.organizationName
            newContact.notes = "" // Optional: you can omit this line
            return newContact
        }

        guard !imported.isEmpty else {
            showAlert(title: "No Contacts Imported", message: "No valid phone numbers found.")
            return
        }
        // Add to manager
        ContactsManager.shared.addCategory(name: "Imported", contacts: imported, to: &categories)

        // Reload UI
        self.loadData()
        self.tableView.reloadData()

        // Notify user
        showAlert(
            title: "Imported",
            message: imported.count == 1
                ? "1 contact was added to the Imported category. You can drag and drop contacts to change category or order."
                : "\(imported.count) contacts were added to the Imported category.You can drag and drop contacts to change category or order."
        )
    }
    @objc private func importContactsTapped() {
        let picker = CNContactPickerViewController()
        picker.delegate = self

        // Show only contacts with at least one phone number
        picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")

        // Limit the fields shown in the picker
        picker.displayedPropertyKeys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey,
            CNContactOrganizationNameKey,
            CNContactJobTitleKey
        ]
        picker.overrideUserInterfaceStyle = UserDefaults.standard.bool(forKey: "nightMode") ? .dark : .light

        present(picker, animated: true)
    }
    @objc private func exportAllContactsTapped() {
        let multiSelectVC = MultiCategorySelectionViewController(categories: categories) { [weak self] selectedCategories in
            guard let self = self else { return }
            
            let fileName = selectedCategories.count == self.categories.count ?
                "contacts_all.shipcontacts" :
                "contacts_selected.shipcontacts"
                
            self.export(categories: selectedCategories, suggestedFileName: fileName)
        }
        
        let nav = UINavigationController(rootViewController: multiSelectVC)
        
        // Apply theme to the navigation controller
        nav.overrideUserInterfaceStyle = UserDefaults.standard.bool(forKey: "nightMode") ? .dark : .light
        ThemeManager.apply(to: nav, traitCollection: nav.traitCollection)
        
        present(nav, animated: true)
    }
    private func export(categories: [ContactCategory], suggestedFileName: String) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        guard let data = try? encoder.encode(categories) else {
            showAlert(title: "Export Failed", message: "Could not encode contacts for export.")
            return
        }

        // Save to temporary file
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(suggestedFileName)

        do {
            try data.write(to: fileURL)
        } catch {
            showAlert(title: "Export Failed", message: "Could not write file.")
            return
        }

        // Create custom subject for email sharing
        let activityVC = UIActivityViewController(
            activityItems: [
                fileURL, // Main file
                "Exported contacts from Ship Pilot Checklists" // This becomes email body or AirDrop context
            ],
            applicationActivities: nil
        )

        activityVC.setValue("Ship Pilot Checklists Contacts Export", forKey: "subject") // For Mail

        activityVC.completionWithItemsHandler = { [weak self] _, completed, _, _ in
            if completed {
                self?.showAlert(title: "Export Complete", message: "Contacts exported successfully.")
            }
        }

        // iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(activityVC, animated: true)
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
        
        // Clean phone number
        let cleanedPhone = contact.phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        guard let url = URL(string: "tel://\(cleanedPhone)") else {
            showAlert(title: "Invalid Number", message: "The phone number format is not valid.")
            return
        }

        // Check if device can make calls
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            showAlert(
                title: "Cannot Make Call",
                message: "This device cannot make phone calls. You may be using an iPad or a device without cellular capability."
            )
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
    private func toolbarButton(title: String, action: Selector) -> UIBarButtonItem {
        let label = UILabel()
        label.text = title
        label.textAlignment = .center
        label.numberOfLines = 2
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = ThemeManager.navBarForegroundColor(for: traitCollection)
        label.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: action)
        label.addGestureRecognizer(tap)

        // Constrain width to keep spacing consistent
        let widthConstraint = label.widthAnchor.constraint(equalToConstant: 70)
        widthConstraint.isActive = true

        return UIBarButtonItem(customView: label)
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
        
        // Only show rows if section is expanded
        guard expandedSections.contains(section) else {
            return 0
        }
        
        return categories[section].contacts.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if isSearching {
            // Simple label for search results
            let label = UILabel()
            label.text = "Search Results"
            label.font = .preferredFont(forTextStyle: .headline)
            label.textColor = .secondaryLabel
            
            let container = UIView()
            container.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])
            return container
        }
        
        // Create a button that acts as the header
        let button = UIButton(type: .system)
        button.tag = section
        button.addTarget(self, action: #selector(toggleSection(_:)), for: .touchUpInside)
        
        // Configure the button appearance
        let isExpanded = expandedSections.contains(section)
        let chevron = isExpanded ? "chevron.down" : "chevron.right"
        
        // Create the title with chevron
        let title = categories[section].name
        button.setTitle(title, for: .normal)
        button.setImage(UIImage(systemName: chevron), for: .normal)
        
        // Style the button
        button.contentHorizontalAlignment = .left
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.tintColor = ThemeManager.titleColor(for: traitCollection)
        
        // Add some padding
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        
        return button
    }
    // 5. Add the height for header:
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }

    // 6. Add the toggle section method:
    @objc private func toggleSection(_ sender: UIButton) {
        let section = sender.tag
        
        if expandedSections.contains(section) {
            expandedSections.remove(section)
        } else {
            expandedSections.insert(section)
        }
        
        // Animate the section reload
        tableView.reloadSections(IndexSet(integer: section), with: .automatic)
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
        
        // Don't allow dragging from collapsed sections
        guard expandedSections.contains(indexPath.section) else { return [] }
        
        let contact = categories[indexPath.section].contacts[indexPath.row]
        let provider = NSItemProvider(object: contact.id.uuidString as NSString)
        let dragItem = UIDragItem(itemProvider: provider)
        dragItem.localObject = (contact, indexPath)
        return [dragItem]
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        // Don't allow drops in collapsed sections
        if let dest = destinationIndexPath, !expandedSections.contains(dest.section) {
            return UITableViewDropProposal(operation: .forbidden)
        }
        
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
                
                // Check if we just added an emergency contact and have a return path
                let categoryName = categories[categoryIndex].name
                if categoryName == "Emergency" && returnToChecklist != nil {
                    // Added emergency contact - trigger return after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if let returnHandler = self.returnToChecklist {
                            self.dismiss(animated: true) {
                                returnHandler()
                            }
                        }
                    }
                }
                
            case .edit(_, let indexPath):
                ContactsManager.shared.updateContact(contact, at: indexPath, in: &categories)
            }
            tableView.reloadData()
        }
    // MARK: - Multi-Category Selection View Controller

    class MultiCategorySelectionViewController: UITableViewController {
        
        private let categories: [ContactCategory]
        private var selectedIndices = Set<Int>()
        private let completion: ([ContactCategory]) -> Void
        
        init(categories: [ContactCategory], completion: @escaping ([ContactCategory]) -> Void) {
            self.categories = categories
            self.completion = completion
            super.init(style: .insetGrouped)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            // Force theme support
            overrideUserInterfaceStyle = UserDefaults.standard.bool(forKey: "nightMode") ? .dark : .light
            
            title = "Select Categories to Export"
            
            // Apply theme colors
            view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
            
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: "Cancel",
                style: .plain,
                target: self,
                action: #selector(cancelTapped)
            )
            
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Export",
                style: .done,
                target: self,
                action: #selector(exportTapped)
            )
            
            // Pre-select all categories
            selectedIndices = Set(0..<categories.count)
            
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
            tableView.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
            
            // Apply navigation bar theme
            updateNavigationBarTheme()
        }
        private func updateNavigationBarTheme() {
            guard let navigationController = navigationController else { return }
            ThemeManager.apply(to: navigationController, traitCollection: traitCollection)
        }
        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            
            // Update theme when switching between light/dark mode
            overrideUserInterfaceStyle = UserDefaults.standard.bool(forKey: "nightMode") ? .dark : .light
            view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
            tableView.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
            updateNavigationBarTheme()
            tableView.reloadData()
        }
        @objc private func cancelTapped() {
            dismiss(animated: true)
        }
        
        @objc private func exportTapped() {
            let selectedCategories = selectedIndices.sorted().map { categories[$0] }
            
            guard !selectedCategories.isEmpty else {
                let alert = UIAlertController(
                    title: "No Categories Selected",
                    message: "Please select at least one category to export.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }
            
            dismiss(animated: true) {
                self.completion(selectedCategories)
            }
        }
        
        // MARK: - Table View Data Source
        
        override func numberOfSections(in tableView: UITableView) -> Int {
            return 1
        }
        
        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return categories.count
        }
        
        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            
            let category = categories[indexPath.row]
            let contactCount = category.contacts.count
            
            cell.textLabel?.text = "\(category.name) (\(contactCount) contacts)"
            cell.textLabel?.textColor = ThemeManager.titleColor(for: traitCollection)
            cell.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
            cell.accessoryType = selectedIndices.contains(indexPath.row) ? .checkmark : .none
            cell.selectionStyle = .none
            
            // Set checkmark color to match theme
            cell.tintColor = ThemeManager.titleColor(for: traitCollection)
            
            return cell
        }
        
        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            if selectedIndices.contains(indexPath.row) {
                selectedIndices.remove(indexPath.row)
            } else {
                selectedIndices.insert(indexPath.row)
            }
            
            tableView.reloadRows(at: [indexPath], with: .none)
        }
        
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            return "Select categories to include in export:"
        }
        
        override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
            let totalSelected = selectedIndices.count
            let totalContacts = selectedIndices.reduce(0) { sum, index in
                sum + categories[index].contacts.count
            }
            
            return totalSelected > 0 ?
                "\(totalSelected) categories selected (\(totalContacts) total contacts)" :
                "No categories selected"
        }
    }
    }
