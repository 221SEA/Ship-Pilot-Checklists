//
//  SettingsViewController.swift
//  Ship Pilot Checklists
//

import UIKit

/// Data model for saving pilot info and emergency contacts
struct EmergencyContact: Codable {
    var name: String
    var phone: String
}

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
In this menu, you can set up fields to be pre-filled for your Emergency SMS and your Post-Incident PDF generation. The PDF will include your profile info and all of the details, photos and notes from your Checklist. See Help for more details. 

In an emergency, tapping the text button at the bottom of a Checklist will send a pre-filled text message containing:
• Your Name
• Vessel Name (prompted, no need to prefill)
• The name of the open Checklist
• Your current GPS fix (from Notes field)
• A short note field you can optionally fill out before hitting send
• Local tide & local wind information (from Notes field, requires internet connection)

Configure up to four contacts below who will receive the Emergency SMS simultaneously.
"""
        return label
    }()

    // MARK: - Data
    private var pilotName: String   = UserDefaults.standard.string(forKey: "pilotName")   ?? ""
    private var pilotGroup: String  = UserDefaults.standard.string(forKey: "pilotGroup")  ?? ""
    private var contacts: [EmergencyContact] = {
        guard let data = UserDefaults.standard.data(forKey: "emergencyContacts"),
              let arr = try? JSONDecoder().decode([EmergencyContact].self, from: data)
        else { return [] }
        return arr
    }()
    
    // Track if changes were made
    private var hasUnsavedChanges = false
    private var saveButton: UIBarButtonItem?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = [.all]
        extendedLayoutIncludesOpaqueBars = true

        title = "Profile"
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)

        setupNavigationBar()
        setupTableView()
        installKeyboardObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
        UserDefaults.standard.setValue(pilotName,  forKey: "pilotName")
        UserDefaults.standard.setValue(pilotGroup, forKey: "pilotGroup")
        if let data = try? JSONEncoder().encode(contacts) {
            UserDefaults.standard.setValue(data, forKey: "emergencyContacts")
        }
        hasUnsavedChanges = false
        updateSaveButtonState()
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
        
        // Don't set tintColor - let it inherit the navigation bar's tint (white)
        navigationItem.rightBarButtonItem = saveButton
        updateSaveButtonState()
    }
    
    private func updateSaveButtonState() {
        saveButton?.isEnabled = hasUnsavedChanges
        updateSaveButtonAppearance()
    }
    
    private func updateSaveButtonAppearance() {
        if hasUnsavedChanges {
            // Make it prominent when there are changes - use white like other nav items
            saveButton?.tintColor = navigationController?.navigationBar.tintColor ?? .white
        } else {
            // Dim it when no changes - use a semi-transparent white
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
        tableView.delegate   = self
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

    private func installKeyboardObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let info = notification.userInfo,
              let kbFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }
        let inset = kbFrame.height
        tableView.contentInset.bottom = inset
        tableView.scrollIndicatorInsets.bottom = inset
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        tableView.contentInset.bottom = 0
        tableView.scrollIndicatorInsets.bottom = 0
    }

    // MARK: - Actions

    @objc private func saveAndClose() {
        persistSettings()
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func saveAndShowConfirmation() {
        persistSettings()
        
        // Show brief confirmation
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

    @objc private func editContact(_ sender: UIButton) {
        let index = sender.tag
        let contact = contacts[index]
        let ac = UIAlertController(title: "Edit Contact",
                                   message: "Update name or phone number",
                                   preferredStyle: .alert)
        ac.addTextField { $0.text = contact.name }
        ac.addTextField { $0.text = contact.phone }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            guard
                let name = ac.textFields?[0].text?.trimmingCharacters(in: .whitespaces),
                let phone = ac.textFields?[1].text?.trimmingCharacters(in: .whitespaces),
                !name.isEmpty, !phone.isEmpty
            else { return }
            self.contacts[index] = EmergencyContact(name: name, phone: phone)
            self.markAsChanged()
            self.tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
        })
        present(ac, animated: true)
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
    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else {
            return contacts.count < 4 ? contacts.count + 1 : contacts.count
        }
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.textColor = ThemeManager.titleColor(for: traitCollection)
        cell.selectionStyle = .none
        cell.accessoryView = nil

        if indexPath.section == 0 {
            // build a text field and use it as the accessoryView so it never overlaps the label
            let width = view.bounds.width * 0.6
            let tf = UITextField(frame: CGRect(x: 0, y: 0, width: width, height: 30))
            tf.borderStyle = .roundedRect
            tf.textAlignment = .right
            tf.textColor = ThemeManager.titleColor(for: traitCollection)

            switch indexPath.row {
            case 0:
                cell.textLabel?.text       = "Pilot Name"
                tf.placeholder             = "Enter your name"
                tf.text                    = pilotName
                tf.addTarget(self,
                             action: #selector(nameChanged(_:)),
                             for: .editingChanged)
            case 1:
                cell.textLabel?.text       = "Pilot Group"
                tf.placeholder             = "Enter your group"
                tf.text                    = pilotGroup
                tf.addTarget(self,
                             action: #selector(groupChanged(_:)),
                             for: .editingChanged)

            default:
                break
            }

            cell.accessoryView = tf

        } else {
            if indexPath.row < contacts.count {
                let contact = contacts[indexPath.row]
                cell.textLabel?.text = "\(contact.name) – \(contact.phone)"
                let pencil = UIButton(type: .system)
                let cfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
                pencil.setImage(UIImage(systemName: "pencil", withConfiguration: cfg), for: .normal)
                pencil.tintColor = ThemeManager.themeColor
                pencil.sizeToFit()
                pencil.tag = indexPath.row
                pencil.addTarget(self, action: #selector(editContact(_:)), for: .touchUpInside)
                cell.accessoryView = pencil
            } else {
                cell.textLabel?.text = "Add Contact"
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 1 else { return }
        if indexPath.row == contacts.count && contacts.count < 4 {
            let ac = UIAlertController(title: "New Contact",
                                       message: "Enter name and phone number",
                                       preferredStyle: .alert)
            ac.addTextField { $0.placeholder = "Name" }
            ac.addTextField { $0.placeholder = "Phone (e.g. +1234567890)" }
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            ac.addAction(UIAlertAction(title: "Add", style: .default) { _ in
                guard
                    let name = ac.textFields?[0].text?.trimmingCharacters(in: .whitespaces),
                    let phone = ac.textFields?[1].text?.trimmingCharacters(in: .whitespaces),
                    !name.isEmpty, !phone.isEmpty
                else { return }
                self.contacts.append(EmergencyContact(name: name, phone: phone))
                self.markAsChanged()
                tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
            })
            present(ac, animated: true)
        }
    }

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath)
    {
        if editingStyle == .delete && indexPath.section == 1 {
            contacts.remove(at: indexPath.row)
            markAsChanged()
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}
