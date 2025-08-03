//
//  ContactsViewController.swift
//  Ship Pilot Checklists
//

import UIKit
import MessageUI
import ContactsUI
import UniformTypeIdentifiers

class ContactsViewController: UIViewController, CNContactPickerDelegate {
    
    // MARK: - Properties
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let searchController = UISearchController(searchResultsController: nil)
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
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
    
    // Section drag properties - ENHANCED
    private var isDraggingSections = false
    private var draggedSectionIndex: Int?
    private var sectionLongPressGesture: UILongPressGestureRecognizer?
    private var draggedHeaderView: UIView?
    private var placeholderView: UIView?
    
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
        
        // FIXED: Listen for import notifications
        setupImportNotifications()
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
        
        // Validate data integrity and reload if needed
        validateDataIntegrity()
        
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
        
        // Add table-level long press for section reordering
        setupSectionReordering()
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
        
        // Enable section reordering (this is the key addition)
        tableView.allowsMultipleSelectionDuringEditing = false
        
        // Register cells
        tableView.register(ContactCell.self, forCellReuseIdentifier: "ContactCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
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

        // UPDATED: Shortened button text to prevent truncation
        bottomToolbar.items = [
            toolbarButton(title: "Add\nContact", action: #selector(addContactTapped)),
            flexible,
            toolbarButton(title: "Batch Add\nContacts", action: #selector(importContactsTapped)),
            flexible,
            toolbarButton(title: "Export\nContacts", action: #selector(exportAllContactsTapped)),
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
    
    // MARK: - Import Notifications
    private func setupImportNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleContactsImported(_:)),
            name: NSNotification.Name("ContactsImported"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNavigateToImported(_:)),
            name: NSNotification.Name("NavigateToImportedContacts"),
            object: nil
        )
    }

    @objc private func handleContactsImported(_ notification: Notification) {
        print("📱 ContactsViewController received import notification")
        
        // Reload data to pick up the new category
        loadData()
        
        // Find the new imported category and expand it
        if let userInfo = notification.userInfo,
           let categoryName = userInfo["categoryName"] as? String,
           let newCategoryIndex = categories.firstIndex(where: { $0.name == categoryName }) {
            
            print("📂 Found imported category '\(categoryName)' at index \(newCategoryIndex)")
            
            // Expand the new section
            expandedSections.insert(newCategoryIndex)
            
            // Reload table
            tableView.reloadData()
            
            print("✅ Expanded section \(newCategoryIndex) for imported category")
        } else {
            print("❌ Could not find imported category in loaded data")
            // Just reload everything
            tableView.reloadData()
        }
    }

    @objc private func handleNavigateToImported(_ notification: Notification) {
        guard let categoryName = notification.object as? String,
              let categoryIndex = categories.firstIndex(where: { $0.name == categoryName }) else {
            print("❌ Could not find category to navigate to")
            return
        }
        
        print("🧭 Navigating to imported category: \(categoryName) at index \(categoryIndex)")
        
        // Ensure section is expanded
        expandedSections.insert(categoryIndex)
        tableView.reloadData()
        
        // Scroll to the imported section after a brief delay to allow the reload to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Check if section has contacts to scroll to
            if categoryIndex < self.tableView.numberOfSections &&
               self.tableView.numberOfRows(inSection: categoryIndex) > 0 {
                let indexPath = IndexPath(row: 0, section: categoryIndex)
                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                
                // Flash the section briefly to draw attention
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let headerView = self.tableView.headerView(forSection: categoryIndex) {
                        let originalBackgroundColor = headerView.backgroundColor
                        
                        UIView.animate(withDuration: 0.2, animations: {
                            headerView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
                        }) { _ in
                            UIView.animate(withDuration: 0.2, delay: 0.5, animations: {
                                headerView.backgroundColor = originalBackgroundColor
                            })
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Data Loading
    private func loadData() {
        let oldCategoryCount = categories.count
        categories = ContactsManager.shared.loadCategories()
        
        print("📊 Loaded \(categories.count) categories (was \(oldCategoryCount))")
        
        // Debug: Print all categories
        for (index, category) in categories.enumerated() {
            print("Category \(index): \(category.name) - \(category.contacts.count) contacts - isSystemCategory: \(category.isSystemCategory)")
        }
        
        // If we have new categories (import), expand them automatically
        if categories.count > oldCategoryCount {
            print("🆕 New categories detected, expanding all sections")
            expandedSections.removeAll()
            for i in 0..<categories.count {
                expandedSections.insert(i)
            }
        } else if expandedSections.isEmpty {
            // First time loading - expand all sections
            for i in 0..<categories.count {
                expandedSections.insert(i)
            }
        } else {
            // Adjust expanded sections if categories were rearranged
            let validSections = Set(0..<categories.count)
            expandedSections = expandedSections.intersection(validSections)
        }
        
        print("📂 Expanded sections: \(expandedSections)")
    }
    
    private func validateDataIntegrity() {
        // Check if our categories array is in sync with what's saved
        let savedCategories = ContactsManager.shared.loadCategories()
        
        if savedCategories.count != categories.count {
            print("⚠️ Data integrity issue detected - reloading data")
            loadData()
            tableView.reloadData()
        }
    }
    
    // MARK: - Section Reordering (ENHANCED Visual Drag and Drop)
    private func setupSectionReordering() {
        // Remove old gesture if it exists
        if let oldGesture = sectionLongPressGesture {
            tableView.removeGestureRecognizer(oldGesture)
        }
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleSectionLongPress(_:)))
        longPress.minimumPressDuration = 0.6
        longPress.delegate = self
        tableView.addGestureRecognizer(longPress)
        sectionLongPressGesture = longPress
        print("Enhanced section reordering gesture added")
    }
    
    @objc private func handleSectionLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: tableView)
        
        switch gesture.state {
        case .began:
            startSectionDrag(at: location, gesture: gesture)
        case .changed:
            updateSectionDrag(to: gesture.location(in: tableView), gesture: gesture)
        case .ended, .cancelled:
            endSectionDrag(gesture: gesture)
        default:
            break
        }
    }
    
    private func startSectionDrag(at location: CGPoint, gesture: UILongPressGestureRecognizer) {
        // Find which section header was pressed
        for section in 0..<categories.count {
            let headerRect = tableView.rectForHeader(inSection: section)
            if headerRect.contains(location) {
                let category = categories[section]
                
                // Don't allow reordering Emergency category
                guard !category.isSystemCategory else {
                    showFeedback("Emergency category cannot be moved")
                    return
                }
                
                startDraggingSection(section, at: location, gesture: gesture)
                return
            }
        }
    }
    
    private func startDraggingSection(_ section: Int, at location: CGPoint, gesture: UILongPressGestureRecognizer) {
        print("Starting visual drag for section: \(section)")
        
        // Set drag state first
        isDraggingSections = true
        draggedSectionIndex = section
        
        // Haptic feedback
        impactFeedback.impactOccurred()
        
        // Create dragged header view
        createDraggedHeaderView(for: section, at: location)
        
        // Only proceed if we successfully created the dragged header
        guard draggedHeaderView != nil else {
            print("Failed to create dragged header view, aborting drag")
            cleanupDragViews()
            return
        }
        
        // Create placeholder view
        createPlaceholderView(for: section)
        
        // Start the drag animation
        UIView.animate(withDuration: 0.2) {
            self.draggedHeaderView?.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            self.draggedHeaderView?.alpha = 0.9
            self.tableView.alpha = 0.8
        }
        
        print("Drag setup complete - isDraggingSections: \(isDraggingSections)")
    }
    
    private func createDraggedHeaderView(for section: Int, at location: CGPoint) {
        // Instead of trying to get the existing header, create a new one directly
        let draggedHeader = SectionHeaderView()
        let category = categories[section]
        let isExpanded = expandedSections.contains(section)
        
        draggedHeader.configure(
            title: category.name,
            isExpanded: isExpanded,
            isEmergencyCategory: false, // We know it's not Emergency since we checked earlier
            section: section,
            traitCollection: traitCollection
        )
        
        // Style the dragged header
        draggedHeader.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        draggedHeader.layer.cornerRadius = 8
        draggedHeader.layer.shadowColor = UIColor.black.cgColor
        draggedHeader.layer.shadowOffset = CGSize(width: 0, height: 4)
        draggedHeader.layer.shadowOpacity = 0.3
        draggedHeader.layer.shadowRadius = 8
        
        // Position it - get header rect and convert to view coordinates
        let headerRect = tableView.rectForHeader(inSection: section)
        let convertedRect = tableView.convert(headerRect, to: view)
        draggedHeader.frame = convertedRect
        
        // Add to view hierarchy
        view.addSubview(draggedHeader)
        draggedHeaderView = draggedHeader
        
        print("Created dragged header at: \(convertedRect)")
    }
    
    private func createPlaceholderView(for section: Int) {
        let placeholder = UIView()
        placeholder.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        placeholder.layer.cornerRadius = 4
        placeholder.layer.borderWidth = 2
        placeholder.layer.borderColor = UIColor.systemBlue.cgColor
        
        let headerRect = tableView.rectForHeader(inSection: section)
        placeholder.frame = headerRect
        
        tableView.addSubview(placeholder)
        placeholderView = placeholder
        
        print("Created placeholder at: \(headerRect)")
    }
    
    private func updateSectionDrag(to location: CGPoint, gesture: UILongPressGestureRecognizer) {
        guard isDraggingSections,
              let draggedHeader = draggedHeaderView,
              let placeholder = placeholderView,
              let draggedSection = draggedSectionIndex else {
            print("updateSectionDrag called but not in dragging state - isDragging: \(isDraggingSections), header: \(draggedHeaderView != nil), placeholder: \(placeholderView != nil), section: \(draggedSectionIndex ?? -1)")
            return
        }
        
        // Convert location from tableView to view coordinates for dragged header
        let viewLocation = tableView.convert(location, to: view)
        
        // Update dragged header position
        draggedHeader.center = CGPoint(x: draggedHeader.center.x, y: viewLocation.y)
        
        // Find which section we're over
        var targetSection: Int?
        
        for section in 0..<categories.count {
            let headerRect = tableView.rectForHeader(inSection: section)
            let expandedRect = CGRect(
                x: headerRect.minX,
                y: headerRect.minY - 22, // Half the header height for better feel
                width: headerRect.width,
                height: headerRect.height + 44 // Full header height buffer
            )
            
            if expandedRect.contains(location) {
                // Don't allow dropping on Emergency category or same section
                if !categories[section].isSystemCategory && section != draggedSection {
                    targetSection = section
                    break
                }
            }
        }
        
        // Update placeholder position
        if let target = targetSection {
            let targetHeaderRect = tableView.rectForHeader(inSection: target)
            
            UIView.animate(withDuration: 0.15) {
                placeholder.frame = targetHeaderRect
                placeholder.alpha = 0.8
            }
        } else {
            // Fade out placeholder when not over valid target
            UIView.animate(withDuration: 0.15) {
                placeholder.alpha = 0.3
            }
        }
    }
    
    private func endSectionDrag(gesture: UILongPressGestureRecognizer) {
        guard isDraggingSections,
              let draggedSection = draggedSectionIndex,
              let draggedHeader = draggedHeaderView else {
            cleanupDragViews()
            return
        }
        
        // Find target section
        let location = gesture.location(in: tableView)
        var targetSection: Int?
        
        for section in 0..<categories.count {
            let headerRect = tableView.rectForHeader(inSection: section)
            let expandedRect = CGRect(
                x: headerRect.minX,
                y: headerRect.minY - 22,
                width: headerRect.width,
                height: headerRect.height + 44
            )
            
            if expandedRect.contains(location) && !categories[section].isSystemCategory && section != draggedSection {
                targetSection = section
                break
            }
        }
        
        if let target = targetSection {
            // Perform the move
            performSectionMove(from: draggedSection, to: target)
            
            // Animate to final position
            let finalHeaderRect = tableView.rectForHeader(inSection: target < draggedSection ? target : target - 1)
            let convertedFinalRect = tableView.convert(finalHeaderRect, to: view)
            
            UIView.animate(withDuration: 0.3, animations: {
                draggedHeader.frame = convertedFinalRect
                draggedHeader.transform = .identity
                draggedHeader.alpha = 1.0
                self.tableView.alpha = 1.0
            }) { _ in
                self.cleanupDragViews()
            }
        } else {
            // Animate back to original position
            let originalHeaderRect = tableView.rectForHeader(inSection: draggedSection)
            let convertedOriginalRect = tableView.convert(originalHeaderRect, to: view)
            
            UIView.animate(withDuration: 0.3, animations: {
                draggedHeader.frame = convertedOriginalRect
                draggedHeader.transform = .identity
                draggedHeader.alpha = 1.0
                self.tableView.alpha = 1.0
            }) { _ in
                self.cleanupDragViews()
            }
            
            showFeedback("Drop on another category to move")
        }
    }
    
    private func performSectionMove(from source: Int, to destination: Int) {
        let actualDestination = source < destination ? destination - 1 : destination
        
        tableView.performBatchUpdates({
            // Move in data model
            let movedCategory = categories.remove(at: source)
            categories.insert(movedCategory, at: actualDestination)
            
            // Save changes
            ContactsManager.shared.saveCategories(categories)
            
            // Update expanded sections tracking
            updateExpandedSectionsAfterMove(from: source, to: actualDestination)
            
            // Move in table view
            tableView.moveSection(source, toSection: actualDestination)
        })
        
        impactFeedback.impactOccurred()
        showFeedback("Category moved successfully")
        print("Moved category from \(source) to \(actualDestination)")
    }
    
    private func cleanupDragViews() {
        print("Cleaning up drag views - isDragging: \(isDraggingSections)")
        
        isDraggingSections = false
        draggedSectionIndex = nil
        
        draggedHeaderView?.removeFromSuperview()
        draggedHeaderView = nil
        
        placeholderView?.removeFromSuperview()
        placeholderView = nil
        
        tableView.alpha = 1.0
        
        print("Drag cleanup complete")
    }
    
    private func updateExpandedSectionsAfterMove(from: Int, to: Int) {
        let wasSourceExpanded = expandedSections.contains(from)
        
        // Remove the moved section
        expandedSections.remove(from)
        
        // Adjust all other expanded sections
        var newExpandedSections = Set<Int>()
        for section in expandedSections {
            var newIndex = section
            
            if section > from {
                newIndex -= 1
            }
            if newIndex >= to {
                newIndex += 1
            }
            
            newExpandedSections.insert(newIndex)
        }
        
        // Add back the moved section if it was expanded
        if wasSourceExpanded {
            newExpandedSections.insert(to)
        }
        
        expandedSections = newExpandedSections
    }
    
    private func showFeedback(_ message: String) {
        // Create a simple toast-like feedback
        let label = UILabel()
        label.text = message
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.alpha = 0
        
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            label.widthAnchor.constraint(lessThanOrEqualToConstant: 250),
            label.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        UIView.animate(withDuration: 0.3, animations: {
            label.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1.5, animations: {
                label.alpha = 0
            }) { _ in
                label.removeFromSuperview()
            }
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
        
        // Apply theme
        picker.overrideUserInterfaceStyle = UserDefaults.standard.bool(forKey: "nightMode") ? .dark : .light
        
        // Add custom navigation title to make purpose clear
        picker.navigationItem.title = "Select Contacts to Import"

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

        // Use JSON extension for universal compatibility
        let baseFileName = suggestedFileName.replacingOccurrences(of: ".shipcontacts", with: "")
        let jsonFileName = "\(baseFileName).json"
        
        // Save to temporary file
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(jsonFileName)

        do {
            try data.write(to: fileURL)
        } catch {
            showAlert(title: "Export Failed", message: "Could not write file.")
            return
        }

        // Enhanced sharing with clear instructions
        let activityVC = UIActivityViewController(
            activityItems: [
                fileURL,
                "Ship Pilot Contacts Export\n\n📋 This file contains contacts from Ship Pilot Checklists app.\n\n📱 To import on another device:\n1. Save this file\n2. Open Ship Pilot Checklists app\n3. File will auto-import when opened\n\n💡 You can also share this file from the Files app directly to Ship Pilot Checklists."
            ],
            applicationActivities: nil
        )

        // Set email subject
        activityVC.setValue("Ship Pilot Contacts - \(baseFileName)", forKey: "subject")

        activityVC.completionWithItemsHandler = { [weak self] activity, completed, _, error in
            if let error = error {
                print("Share error: \(error)")
                self?.showAlert(title: "Share Failed", message: error.localizedDescription)
            } else if completed {
                self?.showAlert(title: "Export Complete", message: "Contacts exported as JSON file for universal compatibility.")
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

        // Use flexible width constraints instead of fixed width
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        // Set minimum width but allow flexibility
        let minWidthConstraint = label.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
        minWidthConstraint.priority = .defaultHigh
        minWidthConstraint.isActive = true

        return UIBarButtonItem(customView: label)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showImportAlert(title: String, message: String, isSuccess: Bool) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if isSuccess {
            // For successful imports, offer to view the imported contacts
            alert.addAction(UIAlertAction(title: "View Imported", style: .default) { [weak self] _ in
                // Find and scroll to the most recent "Imported" category
                guard let self = self else { return }
                
                // Find the imported category (it should be the last one added)
                if let importedIndex = self.categories.lastIndex(where: { $0.name.hasPrefix("Imported") }) {
                    // Expand the section if it's collapsed
                    self.expandedSections.insert(importedIndex)
                    
                    // Scroll to show the imported section
                    let indexPath = IndexPath(row: 0, section: importedIndex)
                    self.tableView.reloadData()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if importedIndex < self.tableView.numberOfSections &&
                           self.tableView.numberOfRows(inSection: importedIndex) > 0 {
                            self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                        }
                    }
                }
            })
            
            alert.addAction(UIAlertAction(title: "OK", style: .default))
        } else {
            // For failed imports, just show OK
            alert.addAction(UIAlertAction(title: "OK", style: .default))
        }
        
        present(alert, animated: true)
    }
    
    // MARK: - Category Editing Methods
    private func editCategoryTapped(at section: Int) {
        let category = categories[section]
        
        let actionSheet = UIAlertController(
            title: category.name,
            message: nil,
            preferredStyle: .actionSheet
        )
        
        // Check if this category can be renamed
        let renameCheckResult = ContactsManager.shared.canRenameCategory(at: section, in: categories)
        if renameCheckResult.canRename {
            actionSheet.addAction(UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
                self?.renameCategoryTapped(at: section)
            })
        }
        
        // Check if this category can be deleted
        let deleteCheckResult = ContactsManager.shared.canDeleteCategory(at: section, in: categories)
        if deleteCheckResult.canDelete {
            // Can delete directly
            actionSheet.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                self?.deleteCategoryTapped(at: section)
            })
        } else if !category.isSystemCategory {
            // Category has contacts but is not Emergency - show delete with confirmation
            actionSheet.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                self?.confirmDeleteCategoryWithContacts(at: section, reason: deleteCheckResult.reason ?? "")
            })
        }
        
        // If this is Emergency category, show explanation
        if category.isSystemCategory {
            actionSheet.message = "The Emergency category is protected and cannot be modified as it's required for the SMS feature."
        }
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // iPad support
        if let popover = actionSheet.popoverPresentationController {
            if let headerView = tableView.headerView(forSection: section) {
                popover.sourceView = headerView
                popover.sourceRect = headerView.bounds
            } else {
                popover.sourceView = tableView
                popover.sourceRect = CGRect(x: tableView.bounds.midX, y: tableView.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
        }
        
        present(actionSheet, animated: true)
    }

    private func renameCategoryTapped(at section: Int) {
        let category = categories[section]
        
        let alert = UIAlertController(
            title: "Rename Category",
            message: "Enter a new name for '\(category.name)'",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.text = category.name
            textField.placeholder = "Category Name"
            textField.autocapitalizationType = .words
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            guard let self = self,
                  let newName = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !newName.isEmpty else { return }
            
            self.categories[section].name = newName
            ContactsManager.shared.saveCategories(self.categories)
            self.tableView.reloadSections(IndexSet(integer: section), with: .none)
        })
        
        present(alert, animated: true)
    }

    private func deleteCategoryTapped(at section: Int) {
        if ContactsManager.shared.deleteCategory(at: section, from: &categories) {
            expandedSections.remove(section)
            // Adjust expanded sections indices
            let adjustedExpanded = expandedSections.compactMap { index in
                index > section ? index - 1 : (index == section ? nil : index)
            }
            expandedSections = Set(adjustedExpanded)
            
            tableView.deleteSections(IndexSet(integer: section), with: .automatic)
        }
    }

    private func confirmDeleteCategoryWithContacts(at section: Int, reason: String) {
        let alert = UIAlertController(
            title: "Delete Category",
            message: reason,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            ContactsManager.shared.forceDeleteCategory(at: section, from: &self.categories)
            self.expandedSections.remove(section)
            
            // Adjust expanded sections indices
            let adjustedExpanded = self.expandedSections.compactMap { index in
                index > section ? index - 1 : (index == section ? nil : index)
            }
            self.expandedSections = Set(adjustedExpanded)
            
            self.tableView.deleteSections(IndexSet(integer: section), with: .automatic)
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ContactsViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Don't allow simultaneous recognition with table view gestures during section drag
        if gestureRecognizer == sectionLongPressGesture {
            return false
        }
        return false
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Only begin if we're not already dragging and not searching
        if gestureRecognizer == sectionLongPressGesture {
            return !isDraggingSections && !isSearching
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // For section drag gesture, only respond to touches in header areas
        if gestureRecognizer == sectionLongPressGesture {
            let location = touch.location(in: tableView)
            
            // Check if touch is in any section header
            for section in 0..<categories.count {
                let headerRect = tableView.rectForHeader(inSection: section)
                if headerRect.contains(location) {
                    return true
                }
            }
            return false
        }
        return true
    }
}

// MARK: - CNContactPickerDelegate
extension ContactsViewController {
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        // Show immediate feedback that processing is happening
        let processingAlert = UIAlertController(
            title: "Importing Contacts",
            message: "Processing \(contacts.count) contact\(contacts.count == 1 ? "" : "s")...",
            preferredStyle: .alert
        )
        
        picker.present(processingAlert, animated: true) {
            // Process contacts in background
            DispatchQueue.global(qos: .userInitiated).async {
                let imported: [OperationalContact] = contacts.compactMap { contact in
                    guard let number = contact.phoneNumbers.first?.value.stringValue else { return nil }
                    
                    var newContact = OperationalContact(
                        name: "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces),
                        phone: number
                    )
                    newContact.email = contact.emailAddresses.first.map { String($0.value) }
                    newContact.organization = contact.organizationName.isEmpty ? nil : contact.organizationName
                    newContact.role = contact.jobTitle.isEmpty ? nil : contact.jobTitle
                    return newContact
                }
                
                DispatchQueue.main.async {
                    // Dismiss processing alert
                    processingAlert.dismiss(animated: true) {
                        // Dismiss the contact picker
                        picker.dismiss(animated: true) {
                            // Handle results
                            guard !imported.isEmpty else {
                                self.showImportAlert(
                                    title: "No Contacts Imported",
                                    message: "No valid phone numbers found in the selected contacts.",
                                    isSuccess: false
                                )
                                return
                            }
                            
                            // Add to manager
                            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
                            let categoryName = "Imported (\(timestamp))"
                            ContactsManager.shared.addCategory(name: categoryName, contacts: imported, to: &self.categories)
                            
                            // FIXED: Use the same notification system as CSV import
                            NotificationCenter.default.post(name: NSNotification.Name("ContactsImported"), object: nil, userInfo: [
                                "categoryName": categoryName,
                                "contactCount": imported.count,
                                "generatedNames": 0,
                                "skippedRows": 0
                            ])
                            
                            // Show success with option to view
                            let message = imported.count == 1
                            ? "1 contact was imported into '\(categoryName)'. You can drag and drop contacts to reorganize them."
                            : "\(imported.count) contacts were imported into '\(categoryName)'. You can drag and drop contacts to reorganize them."
                            
                            let successAlert = UIAlertController(
                                title: "Import Successful",
                                message: message,
                                preferredStyle: .alert
                            )
                            
                            successAlert.addAction(UIAlertAction(title: "View Imported", style: .default) { _ in
                                NotificationCenter.default.post(name: NSNotification.Name("NavigateToImportedContacts"), object: categoryName)
                            })
                            
                            successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                            
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first {
                                window.rootViewController?.present(successAlert, animated: true)
                            }
                        }
                    }
                }
            }
        }
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
        
        // Create custom header view
        let headerView = SectionHeaderView()
        headerView.backgroundColor = .clear
        
        let category = categories[section]
        let isExpanded = expandedSections.contains(section)
        
        headerView.configure(
            title: category.name,
            isExpanded: isExpanded,
            isEmergencyCategory: category.isSystemCategory,
            section: section,
            traitCollection: traitCollection
        )
        
        // Set up actions
        headerView.onToggle = { [weak self] in
            self?.toggleSection(section)
        }
        
        headerView.onEdit = { [weak self] in
            self?.editCategoryTapped(at: section)
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }

    private func toggleSection(_ section: Int) {
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
    
    // MARK: - Section Reordering Support
    func tableView(_ tableView: UITableView, canMoveSection section: Int) -> Bool {
        // Emergency category cannot be moved (it should always stay at index 0)
        return !categories[section].isSystemCategory
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        // This method is for row movement, not section movement
        // We'll handle section movement in the drop delegate
        return proposedDestinationIndexPath
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

// MARK: - Drag & Drop (for contacts only)
extension ContactsViewController: UITableViewDragDelegate, UITableViewDropDelegate {
    
    // MARK: - Drag Delegate Methods
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard !isSearching && !isDraggingSections else { return [] }
        
        // Don't allow dragging from collapsed sections
        guard expandedSections.contains(indexPath.section) else { return [] }
        
        let contact = categories[indexPath.section].contacts[indexPath.row]
        let provider = NSItemProvider(object: contact.id.uuidString as NSString)
        let dragItem = UIDragItem(itemProvider: provider)
        dragItem.localObject = (contact, indexPath)
        return [dragItem]
    }
    
    // MARK: - Drop Delegate Methods (for contact reordering only)
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        // Don't allow drops during section dragging
        guard !isDraggingSections else {
            return UITableViewDropProposal(operation: .forbidden)
        }
        
        // Don't allow drops in collapsed sections
        if let dest = destinationIndexPath, !expandedSections.contains(dest.section) {
            return UITableViewDropProposal(operation: .forbidden)
        }
        
        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        guard let item = coordinator.items.first else {
            print("❌ No drag item found")
            return
        }
        
        // Only handle contact reordering
        guard let (contact, sourceIndexPath) = item.dragItem.localObject as? (OperationalContact, IndexPath),
              let destinationIndexPath = coordinator.destinationIndexPath else {
            print("❌ Invalid drag data or destination")
            return
        }
        
        print("🔄 Attempting to move contact: \(contact.name) from \(sourceIndexPath) to \(destinationIndexPath)")
        
        // Validate that we still have valid data before attempting the move
        guard sourceIndexPath.section < categories.count,
              sourceIndexPath.row < categories[sourceIndexPath.section].contacts.count,
              destinationIndexPath.section < categories.count,
              destinationIndexPath.row <= categories[destinationIndexPath.section].contacts.count else {
            
            print("❌ Invalid indices during drop operation")
            print("   Source: [\(sourceIndexPath.section), \(sourceIndexPath.row)]")
            print("   Destination: [\(destinationIndexPath.section), \(destinationIndexPath.row)]")
            print("   Categories count: \(categories.count)")
            
            if sourceIndexPath.section < categories.count {
                print("   Source section contacts count: \(categories[sourceIndexPath.section].contacts.count)")
            }
            if destinationIndexPath.section < categories.count {
                print("   Destination section contacts count: \(categories[destinationIndexPath.section].contacts.count)")
            }
            
            // Show user feedback
            showAlert(title: "Move Failed", message: "Could not move contact due to invalid position. Please try again.")
            
            // Reload data to ensure UI is consistent with data model
            DispatchQueue.main.async {
                self.loadData()
                self.tableView.reloadData()
            }
            return
        }
        
        // Perform the move with enhanced error handling
        tableView.performBatchUpdates({
            // Move in the data model first
            ContactsManager.shared.moveContact(from: sourceIndexPath, to: destinationIndexPath, in: &self.categories)
            
            // Then update the UI
            tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
            
        }, completion: { success in
            if success {
                print("✅ Contact move completed successfully")
            } else {
                print("❌ Table view batch update failed")
                
                // If the UI update failed, reload everything to ensure consistency
                DispatchQueue.main.async {
                    self.loadData()
                    self.tableView.reloadData()
                    
                    // Show user feedback
                    self.showAlert(title: "Move Completed",
                                  message: "Contact was moved but the display needed to refresh. Your change has been saved.")
                }
            }
        })
    }
    
    // MARK: - Enhanced Drop Session Handling
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        // We can handle contact drags only when not dragging sections
        return !isDraggingSections && session.hasItemsConforming(toTypeIdentifiers: [UTType.text.identifier])
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidEnter session: UIDropSession) {
        // Provide visual feedback when drag enters the table view
        if !isDraggingSections {
            tableView.alpha = 0.9
        }
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidExit session: UIDropSession) {
        // Remove visual feedback when drag exits
        if !isDraggingSections {
            tableView.alpha = 1.0
        }
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidEnd session: UIDropSession) {
        // Ensure we reset visual state
        if !isDraggingSections {
            tableView.alpha = 1.0
        }
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

// MARK: - Custom Section Header View
class SectionHeaderView: UIView {
    private let titleButton = UIButton(type: .system)
    private let dragHandle = UIImageView()
    private let editButton = UIButton(type: .system)
    private let lockIcon = UIImageView()
    
    var onToggle: (() -> Void)?
    var onEdit: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // Configure title button
        titleButton.contentHorizontalAlignment = .left
        titleButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        titleButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        titleButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        titleButton.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside)
        
        // Configure drag handle
        dragHandle.image = UIImage(systemName: "line.3.horizontal")
        dragHandle.contentMode = .scaleAspectFit
        
        // Configure edit button
        editButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        
        // Configure lock icon
        lockIcon.image = UIImage(systemName: "lock.fill")
        lockIcon.contentMode = .scaleAspectFit
        
        // Add subviews
        addSubview(titleButton)
        addSubview(dragHandle)
        addSubview(editButton)
        addSubview(lockIcon)
        
        // Setup constraints
        titleButton.translatesAutoresizingMaskIntoConstraints = false
        dragHandle.translatesAutoresizingMaskIntoConstraints = false
        editButton.translatesAutoresizingMaskIntoConstraints = false
        lockIcon.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Title button
            titleButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Edit button (for non-Emergency categories)
            editButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            editButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            editButton.widthAnchor.constraint(equalToConstant: 30),
            editButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Drag handle (for non-Emergency categories)
            dragHandle.trailingAnchor.constraint(equalTo: editButton.leadingAnchor, constant: -8),
            dragHandle.centerYAnchor.constraint(equalTo: centerYAnchor),
            dragHandle.widthAnchor.constraint(equalToConstant: 24),
            dragHandle.heightAnchor.constraint(equalToConstant: 24),
            
            // Lock icon (for Emergency category only - positioned where drag handle normally is)
            lockIcon.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -52), // Position where drag handle would be
            lockIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
            lockIcon.widthAnchor.constraint(equalToConstant: 16),
            lockIcon.heightAnchor.constraint(equalToConstant: 16),
            
            // Title button trailing constraint
            titleButton.trailingAnchor.constraint(equalTo: dragHandle.leadingAnchor, constant: -8)
        ])
    }
    
    func configure(title: String, isExpanded: Bool, isEmergencyCategory: Bool, section: Int, traitCollection: UITraitCollection) {
        // Set title and chevron
        let chevron = isExpanded ? "chevron.down" : "chevron.right"
        titleButton.setTitle(title, for: .normal)
        titleButton.setImage(UIImage(systemName: chevron), for: .normal)
        
        // Set colors
        let titleColor = ThemeManager.titleColor(for: traitCollection)
        titleButton.tintColor = titleColor
        dragHandle.tintColor = titleColor.withAlphaComponent(0.8)
        editButton.tintColor = titleColor
        lockIcon.tintColor = titleColor.withAlphaComponent(0.4)
        
        // Show/hide elements based on category type
        if isEmergencyCategory {
            // Emergency category: show lock, hide drag handle and edit button
            dragHandle.isHidden = true
            editButton.isHidden = true
            lockIcon.isHidden = false
        } else {
            // Regular categories: show drag handle and edit button, hide lock
            dragHandle.isHidden = false
            editButton.isHidden = false
            lockIcon.isHidden = true
        }
        
        // Store section for edit action
        editButton.tag = section
    }
    
    @objc private func toggleTapped() {
        onToggle?()
    }
    
    @objc private func editTapped() {
        onEdit?()
    }
}
