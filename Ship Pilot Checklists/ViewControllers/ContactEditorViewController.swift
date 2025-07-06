//
//  ContactEditorViewController.swift
//  Ship Pilot Checklists
//

import UIKit
import Contacts
import ContactsUI

// MARK: - Editor Mode
enum ContactEditorMode {
    case add(categoryIndex: Int)
    case edit(contact: OperationalContact, indexPath: IndexPath)
}

// MARK: - Delegate
protocol ContactEditorDelegate: AnyObject {
    func contactEditor(_ editor: ContactEditorViewController, didSave contact: OperationalContact, mode: ContactEditorMode)
}

// MARK: - ContactEditorViewController
class ContactEditorViewController: UIViewController, CNContactPickerDelegate {
    
    // MARK: - Properties
    weak var delegate: ContactEditorDelegate?
    private let mode: ContactEditorMode
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    // Form fields
    private var nameField: UITextField!
    private var roleField: UITextField!
    private var organizationField: UITextField!
    private var phoneField: UITextField!
    private var emailField: UITextField!
    private var vhfChannelField: UITextField!
    private var callSignField: UITextField!
    private var notesTextView: UITextView!
    private var portField: UITextField!
    private var importedContact: CNContact?
    private var contact: OperationalContact?
    
    // MARK: - Initialization
    init(mode: ContactEditorMode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
        
        // If editing, load the contact
        if case .edit(let existingContact, _) = mode {
            self.contact = existingContact
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadContactData()
        setupKeyboardObservers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Auto-focus on name field for new contacts
        if case .add = mode {
            nameField.becomeFirstResponder()
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
        
        // Title
        switch mode {
        case .add:
            title = "New Contact"
        case .edit:
            title = "Edit Contact"
        }
        
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        
        setupNavigationBar()
        setupTableView()
        updateTheme()
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveTapped)
        )
        
        // Disable save until we have required fields
        updateSaveButtonState()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        
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
        
        // Update navigation bar buttons
        let tintColor = ThemeManager.titleColor(for: traitCollection)
        navigationItem.leftBarButtonItem?.tintColor = tintColor
        navigationItem.rightBarButtonItem?.tintColor = tintColor
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
    
    // MARK: - Data
    private func loadContactData() {
        guard case .edit(let existingContact, _) = mode else { return }
        
        // Contact will be loaded when cells are created
        contact = existingContact
    }
    
    private func updateSaveButtonState() {
        let hasName = !(nameField?.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let hasPhone = !(phoneField?.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        
        navigationItem.rightBarButtonItem?.isEnabled = hasName && hasPhone
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        guard let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let phone = phoneField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty, !phone.isEmpty else { return }
        
        let savedContact: OperationalContact
        
        if case .edit(let existingContact, _) = mode {
            // Update existing contact
            var updated = existingContact
            updated.name = name
            updated.phone = phone
            updated.role = roleField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.organization = organizationField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.vhfChannel = vhfChannelField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.callSign = callSignField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.notes = notesTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.port = portField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            savedContact = updated
        } else {
            // Create new contact
            var newContact = OperationalContact(name: name, phone: phone)
            newContact.role = roleField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            newContact.organization = organizationField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            newContact.email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            newContact.vhfChannel = vhfChannelField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            newContact.callSign = callSignField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            newContact.notes = notesTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            newContact.port = portField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            savedContact = newContact
        }
        
        delegate?.contactEditor(self, didSave: savedContact, mode: mode)
        dismiss(animated: true)
    }
    
    @objc private func importFromContacts() {
        let picker = CNContactPickerViewController()
        picker.delegate = self
        
        // Only show contacts with phone numbers
        picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        
        // Specify which properties we want
        picker.displayedPropertyKeys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey,
            CNContactOrganizationNameKey,
            CNContactJobTitleKey
        ]
        
        present(picker, animated: true)
    }
    // MARK: - CNContactPickerDelegate
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        print("Contact selected: \(contact)")
        
        // Store the contact
        self.importedContact = contact
        
        // Reload the table to display the new data
        self.tableView.reloadData()
        
        // Update save button state after a brief delay to ensure fields are created
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateSaveButtonState()
        }
    }

    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        // User cancelled - nothing to do
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension ContactEditorViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4 // Basic Info, Communication, Maritime Info, Notes
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 4 // Name, Role, Organization, Port
        case 1: return 2 // Phone, Email
        case 2: return 2 // VHF Channel, Call Sign
        case 3: return 1 // Notes
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Basic Information"
        case 1: return "Contact"
        case 2: return "Maritime"
        case 3: return "Notes"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none
        
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = .systemFont(ofSize: 17)
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        
        // Configure based on section and row
        switch (indexPath.section, indexPath.row) {
        case (0, 0): // Name
            textField.placeholder = "Name (required)"
            textField.autocapitalizationType = .words
            // Check for imported contact first, then existing contact
            if let imported = importedContact {
                textField.text = CNContactFormatter.string(from: imported, style: .fullName) ?? ""
            } else {
                textField.text = contact?.name
            }
            nameField = textField
            
        case (0, 1): // Role
            textField.placeholder = "Role/Title"
            textField.autocapitalizationType = .words
            // Check for imported contact first
            if let imported = importedContact,
               !imported.jobTitle.isEmpty {
                textField.text = imported.jobTitle
            } else {
                textField.text = contact?.role
            }
            roleField = textField
            
        case (0, 2): // Organization
            textField.placeholder = "Company/Organization"
            textField.autocapitalizationType = .words
            // Check for imported contact first
            if let imported = importedContact,
               !imported.organizationName.isEmpty {
                textField.text = imported.organizationName
            } else {
                textField.text = contact?.organization
            }
            organizationField = textField
            
        case (0, 3): // Port
            textField.placeholder = "Port/Location"
            textField.autocapitalizationType = .words
            textField.text = contact?.port
            portField = textField
            
        case (1, 0): // Phone
            textField.placeholder = "Phone (required)"
            textField.keyboardType = .phonePad
            // Check for imported contact first
            if let imported = importedContact,
               let phone = imported.phoneNumbers.first {
                textField.text = phone.value.stringValue
            } else {
                textField.text = contact?.phone
            }
            phoneField = textField
            
        case (1, 1): // Email
            textField.placeholder = "Email"
            textField.keyboardType = .emailAddress
            textField.autocapitalizationType = .none
            // Check for imported contact first
            if let imported = importedContact,
               let email = imported.emailAddresses.first {
                textField.text = email.value as String
            } else {
                textField.text = contact?.email
            }
            emailField = textField
            
        case (2, 0): // VHF Channel
            textField.placeholder = "VHF Channel (e.g., Ch. 16/68)"
            textField.text = contact?.vhfChannel
            vhfChannelField = textField
            
        case (2, 1): // Call Sign
            textField.placeholder = "Call Sign"
            textField.autocapitalizationType = .allCharacters
            textField.text = contact?.callSign
            callSignField = textField
            
        case (3, 0): // Notes
            // Use text view for notes
            let textView = UITextView()
            textView.translatesAutoresizingMaskIntoConstraints = false
            textView.font = .systemFont(ofSize: 17)
            textView.delegate = self
            textView.text = contact?.notes ?? ""
            textView.textColor = ThemeManager.titleColor(for: traitCollection)
            textView.backgroundColor = .clear
            notesTextView = textView
            
            cell.contentView.addSubview(textView)
            NSLayoutConstraint.activate([
                textView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                textView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                textView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                textView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
                textView.heightAnchor.constraint(equalToConstant: 100)
            ])
            return cell
            
        default:
            break
        }
        
        // Add text field to cell
        if indexPath.section < 3 {
            cell.contentView.addSubview(textField)
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                textField.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                textField.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
            ])
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "Tip: Tap 'Import from Contacts' to quickly add from your phone contacts."
        }
        return nil
    }
}

// MARK: - UITableViewDelegate
extension ContactEditorViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0, case .add = mode {
            // Add import button for first section
            let headerView = UIView()
            headerView.backgroundColor = .clear
            
            let titleLabel = UILabel()
            titleLabel.text = "Basic Information"
            titleLabel.font = .systemFont(ofSize: 13)
            titleLabel.textColor = .secondaryLabel
            
            let importButton = UIButton(type: .system)
            importButton.setTitle("Import from Contacts", for: .normal)
            importButton.titleLabel?.font = .systemFont(ofSize: 15)
            importButton.addTarget(self, action: #selector(importFromContacts), for: .touchUpInside)
            
            headerView.addSubview(titleLabel)
            headerView.addSubview(importButton)
            
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            importButton.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: importButton.leadingAnchor, constant: -8),
                
                importButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
                importButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                
                // Add explicit height constraint
                headerView.heightAnchor.constraint(equalToConstant: 44)
            ])
            
            return headerView
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0, case .add = mode {
            return 44
        }
        return UITableView.automaticDimension
    }
}

// MARK: - UITextFieldDelegate
extension ContactEditorViewController: UITextFieldDelegate {
    @objc private func textFieldChanged(_ textField: UITextField) {
        updateSaveButtonState()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Move to next field
        switch textField {
        case nameField:
            roleField.becomeFirstResponder()
        case roleField:
            organizationField.becomeFirstResponder()
        case organizationField:
            portField.becomeFirstResponder()
        case portField:
            phoneField.becomeFirstResponder()
        case phoneField:
            emailField.becomeFirstResponder()
        case emailField:
            vhfChannelField.becomeFirstResponder()
        case vhfChannelField:
            callSignField.becomeFirstResponder()
        case callSignField:
            notesTextView.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        
        return true
    }
}

// MARK: - UITextViewDelegate
extension ContactEditorViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        // Notes are optional, no need to update save button
    }
}


