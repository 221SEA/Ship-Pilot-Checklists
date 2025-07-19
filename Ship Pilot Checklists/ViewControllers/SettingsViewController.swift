//
//  SettingsViewController.swift
//  Ship Pilot Checklists
//
//  Simplified version - Profile information only
//

import UIKit

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
• PDF generation - Your name and pilot group will appear in the header
• Post-incident reports - All profile information will be included

Make sure to save your changes before leaving this screen.
"""
        return label
    }()

    // MARK: - Data
    private var pilotName: String = UserDefaults.standard.string(forKey: "pilotName") ?? ""
    private var pilotGroup: String = UserDefaults.standard.string(forKey: "pilotGroup") ?? ""
    
    // Track if changes were made
    private var hasUnsavedChanges = false
    private var saveButton: UIBarButtonItem?
    private var keyboardHeight: CGFloat = 0
    
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
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Auto-save when leaving if there are changes
        if hasUnsavedChanges {
            persistSettings()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        tableView.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        tableView.reloadData()
        updateSaveButtonAppearance()
    }

    // MARK: - Persistence
    private func persistSettings() {
        UserDefaults.standard.setValue(pilotName, forKey: "pilotName")
        UserDefaults.standard.setValue(pilotGroup, forKey: "pilotGroup")
        hasUnsavedChanges = false
        updateSaveButtonState()
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
        // Create save button with custom styling
        saveButton = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveAndShowConfirmation)
        )
        
        navigationItem.rightBarButtonItem = saveButton
        updateSaveButtonState()
    }
    
    private func updateSaveButtonState() {
        saveButton?.isEnabled = hasUnsavedChanges
        updateSaveButtonAppearance()
    }
    
    private func updateSaveButtonAppearance() {
        if hasUnsavedChanges {
            // Make it prominent when there are changes
            saveButton?.tintColor = navigationController?.navigationBar.tintColor ?? .white
        } else {
            // Dim it when no changes
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

        // Dynamic header sizing
        let maxWidth = view.bounds.width - 32
        let labelSize = instructionLabel.sizeThatFits(
            CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        )
        let headerHeight = labelSize.height + 24  // 12pt top & bottom padding
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: headerHeight))
        instructionLabel.frame = CGRect(x: 16, y: 12, width: maxWidth, height: labelSize.height)
        header.addSubview(instructionLabel)
        tableView.tableHeaderView = header

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Actions
    // In SettingsViewController.swift, replace the saveAndShowConfirmation method:

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
            
            // Otherwise, show the confirmation animation as before
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

    @objc private func nameChanged(_ tf: UITextField) {
        pilotName = tf.text ?? ""
        markAsChanged()
    }
    
    @objc private func groupChanged(_ tf: UITextField) {
        pilotGroup = tf.text ?? ""
        markAsChanged()
    }
}

// MARK: - UITableViewDataSource & Delegate
extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // Profile section and Emergency Contacts section
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: // Profile
            return 2
        case 1: // Emergency Contacts info
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

        if indexPath.section == 0 {
            // Profile fields
            let width = view.bounds.width * 0.6
            let tf = UITextField(frame: CGRect(x: 0, y: 0, width: width, height: 30))
            tf.borderStyle = .roundedRect
            tf.textAlignment = .right
            tf.textColor = ThemeManager.titleColor(for: traitCollection)

            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Pilot Name"
                tf.placeholder = "Enter your name"
                tf.text = pilotName
                tf.addTarget(self, action: #selector(nameChanged(_:)), for: .editingChanged)
            case 1:
                cell.textLabel?.text = "Pilot Group"
                tf.placeholder = "Enter your group"
                tf.text = pilotGroup
                tf.addTarget(self, action: #selector(groupChanged(_:)), for: .editingChanged)
            default:
                break
            }

            cell.accessoryView = tf
        } else if indexPath.section == 1 {
            // Emergency contacts info
            cell.textLabel?.text = "Manage Emergency Contacts"
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            // Navigate to Contacts with Emergency category pre-selected
            let contactsVC = ContactsViewController()
            contactsVC.openToEmergencyCategory = true
            navigationController?.pushViewController(contactsVC, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 {
            return "Add emergency contacts in the Contacts section. They will appear as options when sending emergency SMS messages."
        }
        return nil
    }
}
