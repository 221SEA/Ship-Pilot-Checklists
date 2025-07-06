import UIKit

protocol ContactSelectionDelegate: AnyObject {
    // UPDATED: Now includes operational contacts
    func contactSelection(_ controller: ContactSelectionViewController,
                          didSelect emergencyContacts: [EmergencyContact],
                          operationalContacts: [OperationalContact])
}

class ContactSelectionViewController: UITableViewController {
    
    // MARK: - Properties
    /// Emergency contacts from profile (must be set before presenting)
    var emergencyContacts: [EmergencyContact] = []
    
    /// Operational contacts loaded from ContactsManager
    private var operationalContacts: [(contact: OperationalContact, category: String)] = []
    
    weak var delegate: ContactSelectionDelegate?

    /// Track selected rows for each section
    private var selectedEmergencyRows = Set<Int>() {
        didSet { updateSendButtonState() }
    }
    
    private var selectedOperationalRows = Set<Int>() {
        didSet { updateSendButtonState() }
    }

    // MARK: – Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // 1) edge-to-edge layout
        edgesForExtendedLayout = [.all]
        extendedLayoutIncludesOpaqueBars = true

        // 2) theme day/night
        overrideUserInterfaceStyle = UserDefaults.standard.bool(forKey: "nightMode") ? .dark : .light

        // 3) background color under nav/status
        tableView.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)

        title = "Choose Recipients"

        // left-bar Cancel
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )

        // right-bar Send Text (starts disabled)
        let send = UIBarButtonItem(
            title: "Send Text",
            style: .done,
            target: self,
            action: #selector(doneTapped)
        )
        send.isEnabled = false
        navigationItem.rightBarButtonItem = send

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.tableFooterView = UIView() // hide empty cells
        
        // Load operational contacts
        loadOperationalContacts()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // make sure our bar buttons pick up the theme tint
        navigationController?.navigationBar.tintColor = ThemeManager.titleColor(for: traitCollection)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // re-apply backgrounds & tints
        overrideUserInterfaceStyle = UserDefaults.standard.bool(forKey: "nightMode") ? .dark : .light
        tableView.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)

        navigationController?.navigationBar.tintColor = ThemeManager.titleColor(for: traitCollection)

        tableView.reloadData()
    }
    
    // MARK: - Data Loading
    private func loadOperationalContacts() {
        let categories = ContactsManager.shared.loadCategories()
        
        // Get frequently used contacts (top 10)
        let frequentContacts = ContactsManager.shared.getFrequentlyUsed(from: categories, limit: 10)
        
        // Convert to our format
        operationalContacts = []
        
        // Add frequent contacts first
        for contact in frequentContacts {
            // Find which category this contact belongs to
            if let category = categories.first(where: { $0.contacts.contains(where: { $0.id == contact.id }) }) {
                operationalContacts.append((contact, category.name))
            }
        }
        
        // If we have fewer than 5 frequent contacts, add some from important categories
        if operationalContacts.count < 5 {
            let importantCategories = ["Port Control", "Coast Guard / Law Enforcement", "Dispatch"]
            
            for categoryName in importantCategories {
                if let category = categories.first(where: { $0.name == categoryName }) {
                    for contact in category.contacts.prefix(2) {
                        // Avoid duplicates
                        if !operationalContacts.contains(where: { $0.contact.id == contact.id }) {
                            operationalContacts.append((contact, category.name))
                        }
                    }
                }
            }
        }
        
        tableView.reloadData()
    }
    
    // MARK: - Helper Methods
    private func updateSendButtonState() {
        navigationItem.rightBarButtonItem?.isEnabled =
            !selectedEmergencyRows.isEmpty || !selectedOperationalRows.isEmpty
    }

    // MARK: – Actions
    @objc private func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func doneTapped() {
        let chosenEmergency = selectedEmergencyRows
            .sorted()
            .map { emergencyContacts[$0] }
        
        let chosenOperational = selectedOperationalRows
            .sorted()
            .map { operationalContacts[$0].contact }
        
        delegate?.contactSelection(self, didSelect: chosenEmergency, operationalContacts: chosenOperational)
    }

    // MARK: – Table
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // Emergency Contacts, Operational Contacts
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return emergencyContacts.count
        case 1:
            return operationalContacts.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return emergencyContacts.isEmpty ? nil : "Emergency Contacts"
        case 1:
            return operationalContacts.isEmpty ? nil : "Operational Contacts (Suggested)"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 && !operationalContacts.isEmpty {
            return "Showing frequently used and important contacts"
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.selectionStyle = .none
        
        switch indexPath.section {
        case 0: // Emergency Contacts
            let contact = emergencyContacts[indexPath.row]
            cell.textLabel?.text = "\(contact.name) – \(contact.phone)"
            cell.textLabel?.numberOfLines = 1
            
            // Checkbox on the left
            let imageName = selectedEmergencyRows.contains(indexPath.row)
                ? "checkmark.square.fill"
                : "square"
            cell.imageView?.image = UIImage(systemName: imageName)
            
        case 1: // Operational Contacts
            let (contact, category) = operationalContacts[indexPath.row]
            
            // Format the display
            var displayText = contact.name
            if let role = contact.role {
                displayText += " (\(role))"
            }
            displayText += " – \(contact.phone)"
            
            // Show category in secondary color
            let attributedText = NSMutableAttributedString(string: displayText)
            attributedText.append(NSAttributedString(string: "\n\(category)", attributes: [
                .foregroundColor: UIColor.secondaryLabel,
                .font: UIFont.systemFont(ofSize: 13)
            ]))
            
            cell.textLabel?.attributedText = attributedText
            cell.textLabel?.numberOfLines = 2
            
            // Checkbox on the left
            let imageName = selectedOperationalRows.contains(indexPath.row)
                ? "checkmark.square.fill"
                : "square"
            cell.imageView?.image = UIImage(systemName: imageName)
            
        default:
            break
        }
        
        cell.textLabel?.textColor = ThemeManager.titleColor(for: traitCollection)
        cell.imageView?.tintColor = ThemeManager.titleColor(for: traitCollection)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            toggle(emergencyRow: indexPath.row)
        case 1:
            toggle(operationalRow: indexPath.row)
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Operational contacts need more height for 2 lines
        return indexPath.section == 1 ? 60 : 44
    }

    private func toggle(emergencyRow row: Int) {
        if selectedEmergencyRows.contains(row) {
            selectedEmergencyRows.remove(row)
        } else {
            selectedEmergencyRows.insert(row)
        }
        tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
    }
    
    private func toggle(operationalRow row: Int) {
        if selectedOperationalRows.contains(row) {
            selectedOperationalRows.remove(row)
        } else {
            selectedOperationalRows.insert(row)
        }
        tableView.reloadRows(at: [IndexPath(row: row, section: 1)], with: .none)
    }
}
