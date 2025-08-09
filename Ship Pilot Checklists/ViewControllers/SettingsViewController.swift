//
//  SettingsViewController.swift
//  Ship Pilot Checklists
//
//  Enhanced version with photo uploads and customization options
//

import UIKit
import PhotosUI

class SettingsViewController: UIViewController {

    // MARK: - UI Elements
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = .systemFont(ofSize: 20)
        label.textColor = .secondaryLabel
        label.text = """
Set up your profile information here. This will be used in:

• Emergency SMS messages - Your name will be included
• PDF generation - Your name and organization will appear in the header
• Post-incident reports - All profile information will be included

You can also customize the app's main screen title and add photos.
"""
        return label
    }()

    // MARK: - Profile Photo Views
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 50
        imageView.backgroundColor = .systemGray5
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = .systemGray3
        return imageView
    }()
    
    // Create vessel image view dynamically to avoid reuse issues
    private func createVesselImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray6
        
        // Load vessel photo if exists
        if let vesselPhotoData = UserDefaults.standard.data(forKey: "vesselPhoto"),
           let vesselImage = UIImage(data: vesselPhotoData) {
            imageView.image = vesselImage
        }
        
        return imageView
    }

    // MARK: - Data
    private var selectedTitle: String = UserDefaults.standard.string(forKey: "userTitle") ?? "Pilot"
    private var userName: String = UserDefaults.standard.string(forKey: "userName") ?? ""
    private var organization: String = UserDefaults.standard.string(forKey: "organization") ?? ""
    private var vesselName: String = UserDefaults.standard.string(forKey: "vesselName") ?? ""
    private var mainScreenTitle: String = UserDefaults.standard.string(forKey: "mainScreenTitle") ?? "Ship Pilot"
    private var useCustomMainTitle: Bool = UserDefaults.standard.bool(forKey: "useCustomMainTitle")
    
    private let titleOptions = ["Pilot", "Captain", "Watch Officer", "Crew"]
    
    // Track if changes were made
    private var hasUnsavedChanges = false
    private var saveButton: UIBarButtonItem?
    
    // Track if we came from PDF generation
    var cameFromPDFGeneration = false
    var returnToChecklist: (() -> Void)?
    var returnToChecklistForPDF: (() -> Void)?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = [.all]
        extendedLayoutIncludesOpaqueBars = true
        overrideUserInterfaceStyle = UserDefaults.standard.bool(forKey: "nightMode") ? .dark : .light

        title = "Profile"
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)

        setupNavigationBar()
        setupTableView()
        setupKeyboardObservers()
        loadPhotos()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update table header view frame when view layout changes
        if let headerView = tableView.tableHeaderView {
            let size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            if headerView.frame.size.height != size.height {
                headerView.frame.size.height = size.height
                tableView.tableHeaderView = headerView
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Don't auto-save here anymore - only save on explicit actions
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        tableView.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        tableView.reloadData()
        updateSaveButtonAppearance()
    }

    // MARK: - Photo Loading
    private func loadPhotos() {
        // Load profile photo
        if let profilePhotoData = UserDefaults.standard.data(forKey: "profilePhoto"),
           let profileImage = UIImage(data: profilePhotoData) {
            profileImageView.image = profileImage
        }
        
        // Note: Vessel photo is loaded when creating the image view
    }

    // MARK: - Persistence
    private func persistSettings() {
        // Save all settings synchronously to avoid issues
        UserDefaults.standard.set(selectedTitle, forKey: "userTitle")
        UserDefaults.standard.set(userName, forKey: "userName")
        UserDefaults.standard.set(organization, forKey: "organization")
        UserDefaults.standard.set(vesselName, forKey: "vesselName")
        UserDefaults.standard.set(mainScreenTitle, forKey: "mainScreenTitle")
        UserDefaults.standard.set(useCustomMainTitle, forKey: "useCustomMainTitle")
        
        // Legacy support - save as pilotName and pilotGroup for compatibility
        let fullName = "\(selectedTitle) \(userName)".trimmingCharacters(in: .whitespaces)
        UserDefaults.standard.set(fullName, forKey: "pilotName")
        UserDefaults.standard.set(organization, forKey: "pilotGroup")
        
        hasUnsavedChanges = false
        updateSaveButtonState()
        
        // Post notification to update main screen if needed
        NotificationCenter.default.post(name: NSNotification.Name("UpdateMainScreenTitle"), object: nil)
    }

    // MARK: - Keyboard Handling
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        
        tableView.contentInset = contentInsets
        tableView.scrollIndicatorInsets = contentInsets
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        tableView.contentInset = .zero
        tableView.scrollIndicatorInsets = .zero
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup
    private func setupNavigationBar() {
        // Add a close/done button on the left
        let closeButton = UIBarButtonItem(
            title: "Done",
            style: .plain,
            target: self,
            action: #selector(dismissViewController)
        )
        navigationItem.leftBarButtonItem = closeButton
        
        // Keep the save button on the right
        saveButton = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveAndShowConfirmation)
        )
        
        navigationItem.rightBarButtonItem = saveButton
        updateSaveButtonState()
    }
    @objc private func dismissViewController() {
        // Auto-save if there are unsaved changes
        if hasUnsavedChanges {
            persistSettings()
        }
        
        // Check if we're in a navigation controller or presented modally
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    private func updateSaveButtonState() {
        saveButton?.isEnabled = hasUnsavedChanges
        updateSaveButtonAppearance()
    }
    
    private func updateSaveButtonAppearance() {
        if hasUnsavedChanges {
            saveButton?.tintColor = navigationController?.navigationBar.tintColor ?? .white
        } else {
            saveButton?.tintColor = UIColor.white.withAlphaComponent(0.5)
        }
    }
    
    private func markAsChanged() {
        hasUnsavedChanges = true
        updateSaveButtonState()
    }



    


    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)

        // Create header with profile photo
        let headerView = UIView()
        
        // Add hint label below profile photo
        let photoHintLabel = UILabel()
        photoHintLabel.text = "Tap to add photo"
        photoHintLabel.font = .systemFont(ofSize: 12)
        photoHintLabel.textColor = .systemGray
        photoHintLabel.textAlignment = .center
        photoHintLabel.translatesAutoresizingMaskIntoConstraints = false
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(profileImageView)
        headerView.addSubview(photoHintLabel)
        headerView.addSubview(instructionLabel)

        // Calculate actual width for instruction label on iPad
        let screenWidth = UIScreen.main.bounds.width
        let instructionMaxWidth = min(screenWidth - 32, 600)
        let instructionLeadingPadding = UIDevice.current.userInterfaceIdiom == .pad ?
            (screenWidth - instructionMaxWidth) / 2 : 16

        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            profileImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            
            photoHintLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 4),
            photoHintLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            photoHintLabel.leadingAnchor.constraint(greaterThanOrEqualTo: headerView.leadingAnchor, constant: 16),
            photoHintLabel.trailingAnchor.constraint(lessThanOrEqualTo: headerView.trailingAnchor, constant: -16),
            
            instructionLabel.topAnchor.constraint(equalTo: photoHintLabel.bottomAnchor, constant: 16),
            instructionLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: instructionLeadingPadding),
            instructionLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -instructionLeadingPadding),
            instructionLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -12)
        ])

        // Add tap gesture to profile photo
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profilePhotoTapped))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(tapGesture)
        
        // Calculate header height using the actual constrained width
        let labelSize = instructionLabel.sizeThatFits(
            CGSize(width: instructionMaxWidth, height: .greatestFiniteMagnitude)
        )
        
        // Add extra padding for iPad
        let basePadding: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 30 : 20
        // Components: profileImage(100) + topPadding + hintLabel(~15) + spacing(4) + spacing(16) + instructionLabel + bottomPadding(12)
        let headerHeight = 100 + basePadding + 4 + 15 + 16 + labelSize.height + 12
        
        headerView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: headerHeight)
        
        // Force the header view to layout its subviews
        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()
        
        tableView.tableHeaderView = headerView

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Actions
    @objc private func saveAndShowConfirmation() {
        persistSettings()
        
        // If we have a return path for PDF generation, use it
        if let pdfReturnHandler = returnToChecklistForPDF {
            dismiss(animated: true) {
                pdfReturnHandler()
            }
            return
        }
        
        // If we have a return path for emergency SMS flow, use it
        if let returnHandler = returnToChecklist {
            dismiss(animated: true) {
                returnHandler()
            }
            return
        }
        
        // If we came from PDF generation, go back immediately
        if cameFromPDFGeneration {
            navigationController?.popViewController(animated: true)
            return
        }
        
        // Otherwise, show the confirmation animation
        showSaveConfirmation()
    }
    
    private func showSaveConfirmation() {
        let checkmark = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkmark.tintColor = .systemGreen
        checkmark.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.text = "Saved"
        label.textColor = .label
        label.font = .systemFont(ofSize: 16, weight: .medium)
        
        let containerView = UIView()
        containerView.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.2
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        
        containerView.addSubview(checkmark)
        containerView.addSubview(label)
        
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            checkmark.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            checkmark.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            checkmark.widthAnchor.constraint(equalToConstant: 24),
            checkmark.heightAnchor.constraint(equalToConstant: 24),
            
            label.leadingAnchor.constraint(equalTo: checkmark.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        containerView.alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.3, animations: {
            containerView.alpha = 1
            containerView.transform = .identity
        }) { _ in
            UIView.animate(withDuration: 0.2, delay: 0.5, options: [], animations: {
                containerView.alpha = 0
                containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }) { _ in
                containerView.removeFromSuperview()
            }
        }
    }

    // MARK: - Photo Selection
    @objc private func profilePhotoTapped() {
        presentPhotoOptions(for: .profile)
    }
    
    @objc private func vesselPhotoTapped() {
        presentPhotoOptions(for: .vessel)
    }
    
    private enum PhotoType {
        case profile
        case vessel
    }
    
    private func presentPhotoOptions(for type: PhotoType) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Choose Photo", style: .default) { _ in
            self.presentPhotoPicker(for: type)
        })
        
        let hasPhoto: Bool
        if type == .profile {
            hasPhoto = profileImageView.image != UIImage(systemName: "person.circle.fill")
        } else {
            // Check if vessel photo exists in UserDefaults
            hasPhoto = UserDefaults.standard.data(forKey: "vesselPhoto") != nil
        }
        
        if hasPhoto {
            alert.addAction(UIAlertAction(title: "Remove Photo", style: .destructive) { _ in
                self.removePhoto(for: type)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // iPad compatibility
        if let popover = alert.popoverPresentationController {
            if type == .profile {
                popover.sourceView = profileImageView
                popover.sourceRect = profileImageView.bounds
            } else {
                // For vessel photo, use the table cell as source
                if let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 1)) {
                    popover.sourceView = cell
                    popover.sourceRect = cell.bounds
                }
            }
        }
        
        present(alert, animated: true)
    }
    
    private func presentPhotoPicker(for type: PhotoType) {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        picker.view.tag = type == .profile ? 1 : 2  // Use tag to identify which photo type
        present(picker, animated: true)
    }
    
    private func removePhoto(for type: PhotoType) {
        if type == .profile {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .systemGray3
            UserDefaults.standard.removeObject(forKey: "profilePhoto")
        } else {
            UserDefaults.standard.removeObject(forKey: "vesselPhoto")
            tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
        }
        markAsChanged()
    }

    // MARK: - Text Field Actions
    @objc private func nameChanged(_ tf: UITextField) {
        userName = tf.text ?? ""
        markAsChanged()
    }
    
    @objc private func organizationChanged(_ tf: UITextField) {
        organization = tf.text ?? ""
        markAsChanged()
        updateMainScreenTitleOptions()
    }
    
    @objc private func vesselNameChanged(_ tf: UITextField) {
        vesselName = tf.text ?? ""
        markAsChanged()
        updateMainScreenTitleOptions()
    }
    
    private func updateMainScreenTitleOptions() {
        // Update the main screen title based on current selection
        if useCustomMainTitle {
            if mainScreenTitle == organization && !organization.isEmpty {
                // Keep using organization
                mainScreenTitle = organization
            } else if mainScreenTitle == vesselName && !vesselName.isEmpty {
                // Keep using vessel name
                mainScreenTitle = vesselName
            } else if !organization.isEmpty {
                // Default to organization if available
                mainScreenTitle = organization
            } else if !vesselName.isEmpty {
                // Otherwise use vessel name
                mainScreenTitle = vesselName
            } else {
                // Fall back to default
                mainScreenTitle = "Ship Pilot"
                useCustomMainTitle = false
            }
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4 // Profile, Vessel, App Customization, Emergency Contacts
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: // Profile
            return 3 // Title dropdown, Name, Organization
        case 1: // Vessel
            return 2 // Vessel name, Vessel photo
        case 2: // App Customization
            return 1 // Main screen title
        case 3: // Emergency Contacts
            return 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Profile Information"
        case 1:
            return "Vessel Information"
        case 2:
            return "App Customization"
        case 3:
            return "Emergency Contacts"
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.textColor = ThemeManager.titleColor(for: traitCollection)
        cell.selectionStyle = .none
        cell.accessoryView = nil
        cell.accessoryType = .none

        switch indexPath.section {
        case 0: // Profile section
            switch indexPath.row {
            case 0: // Title dropdown
                cell.textLabel?.text = "Title"
                
                // Create a more obvious dropdown button
                let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 120, height: 30))
                
                let button = UIButton(type: .system)
                button.setTitle(selectedTitle, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 17)
                button.contentHorizontalAlignment = .trailing
                button.addTarget(self, action: #selector(titleButtonTapped), for: .touchUpInside)
                button.frame = CGRect(x: 0, y: 0, width: 90, height: 30)
                
                // Add dropdown arrow indicator
                let arrowLabel = UILabel(frame: CGRect(x: 95, y: 0, width: 20, height: 30))
                arrowLabel.text = "▼"
                arrowLabel.textColor = .systemGray
                arrowLabel.font = .systemFont(ofSize: 12)
                
                containerView.addSubview(button)
                containerView.addSubview(arrowLabel)
                
                cell.accessoryView = containerView
                
            case 1: // Name
                cell.textLabel?.text = "Name"
                let tf = createTextField(placeholder: "Enter your name", text: userName)
                tf.addTarget(self, action: #selector(nameChanged(_:)), for: .editingChanged)
                cell.accessoryView = tf
                
            case 2: // Organization
                cell.textLabel?.text = "Organization (Optional)"
                let tf = createTextField(placeholder: "Enter organization", text: organization)
                tf.addTarget(self, action: #selector(organizationChanged(_:)), for: .editingChanged)
                cell.accessoryView = tf
                
            default:
                break
            }
            
        case 1: // Vessel section
            switch indexPath.row {
            case 0: // Vessel name
                cell.textLabel?.text = "Vessel Name (Optional)"
                let tf = createTextField(placeholder: "Enter vessel name", text: vesselName)
                tf.addTarget(self, action: #selector(vesselNameChanged(_:)), for: .editingChanged)
                cell.accessoryView = tf
                
            case 1: // Vessel photo
                cell.textLabel?.text = "Vessel Photo"
                cell.detailTextLabel?.text = "Tap to add photo"
                cell.detailTextLabel?.textColor = .systemGray
                
                // Check if vessel photo exists
                if let vesselPhotoData = UserDefaults.standard.data(forKey: "vesselPhoto"),
                   let vesselImage = UIImage(data: vesselPhotoData) {
                    // Create fresh image view
                    let vesselImageView = createVesselImageView()
                    
                    // Create a container view for the image
                    let containerView = UIView()
                    containerView.addSubview(vesselImageView)
                    
                    vesselImageView.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        vesselImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                        vesselImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                        vesselImageView.widthAnchor.constraint(equalToConstant: 40),
                        vesselImageView.heightAnchor.constraint(equalToConstant: 40)
                    ])
                    
                    containerView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
                    cell.accessoryView = containerView
                    cell.detailTextLabel?.text = nil
                }
                
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
                
            default:
                break
            }
            
        case 2: // App Customization
            cell.textLabel?.text = "Main Screen Title"
            cell.textLabel?.numberOfLines = 2
            cell.textLabel?.font = .systemFont(ofSize: 15)
            
            if useCustomMainTitle && !mainScreenTitle.isEmpty && mainScreenTitle != "Ship Pilot" {
                cell.detailTextLabel?.text = mainScreenTitle
            } else {
                cell.detailTextLabel?.text = "Ship Pilot (Default)"
            }
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            
        case 3: // Emergency contacts
            cell.textLabel?.text = "Manage Emergency Contacts"
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            
        default:
            break
        }

        return cell
    }

    private func createTextField(placeholder: String, text: String) -> UITextField {
        let width = view.bounds.width * 0.5
        let tf = UITextField(frame: CGRect(x: 0, y: 0, width: width, height: 30))
        tf.borderStyle = .roundedRect
        tf.textAlignment = .right
        tf.textColor = ThemeManager.titleColor(for: traitCollection)
        tf.placeholder = placeholder
        tf.text = text
        return tf
    }

    @objc private func titleButtonTapped() {
        let picker = UIAlertController(title: "Select Title", message: nil, preferredStyle: .actionSheet)
        
        for title in titleOptions {
            picker.addAction(UIAlertAction(title: title, style: .default) { _ in
                self.selectedTitle = title
                self.markAsChanged()
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
            })
        }
        
        picker.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // iPad compatibility
        if let popover = picker.popoverPresentationController {
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) {
                popover.sourceView = cell
                popover.sourceRect = cell.bounds
            }
        }
        
        present(picker, animated: true)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 1:
            if indexPath.row == 1 { // Vessel photo
                vesselPhotoTapped()
            }
            
        case 2: // App Customization
            presentMainScreenTitleOptions()
            
        case 3: // Emergency contacts
            let contactsVC = ContactsViewController()
            contactsVC.openToEmergencyCategory = true
            navigationController?.pushViewController(contactsVC, animated: true)
            
        default:
            break
        }
    }
    
    private func presentMainScreenTitleOptions() {
        let alert = UIAlertController(
            title: "Main Screen Title",
            message: "Choose what to display at the top of the main screen",
            preferredStyle: .actionSheet
        )
        
        // Default option
        alert.addAction(UIAlertAction(title: "Ship Pilot (Default)", style: .default) { _ in
            self.mainScreenTitle = "Ship Pilot"
            self.useCustomMainTitle = false
            self.markAsChanged()
            self.tableView.reloadSections(IndexSet(integer: 2), with: .none)
        })
        
        // Organization option (if available)
        if !organization.isEmpty {
            alert.addAction(UIAlertAction(title: "Organization: \(organization)", style: .default) { _ in
                self.mainScreenTitle = self.organization
                self.useCustomMainTitle = true
                self.markAsChanged()
                self.tableView.reloadSections(IndexSet(integer: 2), with: .none)
            })
        }
        
        // Vessel name option (if available)
        if !vesselName.isEmpty {
            alert.addAction(UIAlertAction(title: "Vessel: \(vesselName)", style: .default) { _ in
                self.mainScreenTitle = self.vesselName
                self.useCustomMainTitle = true
                self.markAsChanged()
                self.tableView.reloadSections(IndexSet(integer: 2), with: .none)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // iPad compatibility
        if let popover = alert.popoverPresentationController {
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 2)) {
                popover.sourceView = cell
                popover.sourceRect = cell.bounds
            }
        }
        
        present(alert, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 1:
            return "Add a vessel photo that will appear in generated PDFs."
        case 2:
            return "Customize what appears at the top of the main screen. Choose between the default 'Ship Pilot', your organization name, or vessel name."
        case 3:
            return "Add emergency contacts in the Contacts section. They will appear as options when sending emergency SMS messages."
        default:
            return nil
        }
    }
}

// MARK: - PHPickerViewControllerDelegate
extension SettingsViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        let isProfilePhoto = picker.view.tag == 1
        
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
            guard let self = self,
                  let image = object as? UIImage,
                  error == nil else { return }
            
            DispatchQueue.main.async {
                // Resize image to reasonable size to save memory
                let maxSize: CGFloat = 500
                let resizedImage = self.resizeImage(image, maxDimension: maxSize)
                
                if isProfilePhoto {
                    self.profileImageView.image = resizedImage
                    if let imageData = resizedImage.jpegData(compressionQuality: 0.8) {
                        UserDefaults.standard.set(imageData, forKey: "profilePhoto")
                    }
                } else {
                    if let imageData = resizedImage.jpegData(compressionQuality: 0.8) {
                        UserDefaults.standard.set(imageData, forKey: "vesselPhoto")
                    }
                    // Reload the vessel photo cell
                    self.tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
                }
                
                self.markAsChanged()
            }
        }
    }
    
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        
        if ratio >= 1.0 {
            return image // No need to resize
        }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
}
