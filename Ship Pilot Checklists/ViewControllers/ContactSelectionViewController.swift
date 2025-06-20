import UIKit

protocol ContactSelectionDelegate: AnyObject {
    func contactSelection(_ controller: ContactSelectionViewController,
                          didSelect contacts: [EmergencyContact])
}

class ContactSelectionViewController: UITableViewController {
    /// Must be set before presenting
    var contacts: [EmergencyContact] = []
    weak var delegate: ContactSelectionDelegate?

    /// track selected rows
    private var selectedRows = Set<Int>() {
        didSet {
            navigationItem.rightBarButtonItem?.isEnabled = !selectedRows.isEmpty
        }
    }

    // MARK: – Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1) edge-to-edge layout
        edgesForExtendedLayout = [.all]
        extendedLayoutIncludesOpaqueBars = true

        // 2) theme day/night
        overrideUserInterfaceStyle =
          UserDefaults.standard.bool(forKey: "nightMode") ? .dark : .light

        // 3) background color under nav/status
        tableView.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        view.backgroundColor      = ThemeManager.backgroundColor(for: traitCollection)

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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // make sure our bar buttons pick up the theme tint
        navigationController?.navigationBar.tintColor =
          ThemeManager.titleColor(for: traitCollection)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // re-apply backgrounds & tints
        overrideUserInterfaceStyle =
          UserDefaults.standard.bool(forKey: "nightMode") ? .dark : .light
        tableView.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        view.backgroundColor      = ThemeManager.backgroundColor(for: traitCollection)

        navigationController?.navigationBar.tintColor =
          ThemeManager.titleColor(for: traitCollection)

        tableView.reloadData()
    }

    // MARK: – Actions

    @objc private func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func doneTapped() {
        let chosen = selectedRows
                      .sorted()
                      .map { contacts[$0] }
        delegate?.contactSelection(self, didSelect: chosen)
    }

    // MARK: – Table

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        contacts.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "Cell",
            for: indexPath
        )
        let c = contacts[indexPath.row]
        cell.textLabel?.text      = "\(c.name) – \(c.phone)"
        cell.textLabel?.textColor = ThemeManager.titleColor(for: traitCollection)
        cell.selectionStyle        = .none

        // checkbox on the left
        let imageName = selectedRows.contains(indexPath.row)
                      ? "checkmark.square.fill"
                      : "square"
        cell.imageView?.image     = UIImage(systemName: imageName)
        cell.imageView?.tintColor = ThemeManager.titleColor(for: traitCollection)

        return cell
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        toggle(row: indexPath.row)
    }

    private func toggle(row: Int) {
        if selectedRows.contains(row) {
            selectedRows.remove(row)
        } else {
            selectedRows.insert(row)
        }
        tableView.reloadRows(
          at: [IndexPath(row: row, section: 0)],
          with: .none
        )
    }
}
