import UIKit

class GroupChecklistListViewController: UIViewController,
                                        UITableViewDataSource,
                                        UITableViewDelegate {

    var groupCode: String!
    var checklists: [ChecklistInfo] = []

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1) allow our view to extend under nav bar & home indicator
        edgesForExtendedLayout = [.all]
        extendedLayoutIncludesOpaqueBars = true

        // 2) day/night and theming
        overrideUserInterfaceStyle = UserDefaults.standard.bool(forKey: "nightMode")
            ? .dark : .light
        title = "Group Checklists"
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)

        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.setNeedsLayout()
        navigationController?.navigationBar.layoutIfNeeded()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        ThemeManager.apply(to: navigationController, traitCollection: traitCollection)
        tableView.reloadData()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(
            ChecklistMenuCell.self,
            forCellReuseIdentifier: "ChecklistMenuCell"
        )
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            // now under-laps the nav bar and stretches full screen
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return checklists.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let checklist = checklists[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "ChecklistMenuCell",
            for: indexPath
        ) as! ChecklistMenuCell
        cell.configure(with: checklist)

        cell.favoriteTapped = { [weak self] in
            checklist.isFavorite.toggle()
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }

        cell.addTapped = { [weak self] in
            let newChecklist = checklist.convertToCustom()
            CustomChecklistManager.shared.add(newChecklist)

            let editorVC = CustomChecklistEditorViewController()
            editorVC.checklist = newChecklist
            self?.navigationController?.pushViewController(editorVC, animated: true)
        }

        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let checklist = checklists[indexPath.row]
        let checklistVC = ChecklistViewController()
        checklistVC.checklist = checklist
        navigationController?.pushViewController(checklistVC, animated: true)
    }
}
