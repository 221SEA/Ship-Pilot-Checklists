//
//  CustomChecklistListViewController.swift
//  Ship Pilot Checklists
//

import UIKit

class CustomChecklistListViewController: UIViewController,
                                          UITableViewDataSource,
                                          UITableViewDelegate,
                                          UITableViewDragDelegate,
                                          UITableViewDropDelegate {

    // MARK: - Data
    private var checklists: [CustomChecklist] = []

    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .plain)

    // “Add New Checklist +” button at the top
    private lazy var addNewButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Add New Checklist +", for: .normal)
        btn.backgroundColor = ThemeManager.themeColor
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        btn.layer.cornerRadius = 8
        btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        btn.addTarget(self, action: #selector(createNewChecklist), for: .touchUpInside)
        return btn
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1) Extend content under navigation bar & home indicator
        edgesForExtendedLayout = [.all]
        extendedLayoutIncludesOpaqueBars = true

        // 2) Force day/night mode
        overrideUserInterfaceStyle = UserDefaults.standard.bool(forKey: "nightMode")
            ? .dark : .light

        // 3) Title and background
        title = "Custom Checklists"
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)

        // 4) Load saved custom checklists
        checklists = CustomChecklistManager.shared.loadAll()

        // 5) Add subviews: button + table
        view.addSubview(addNewButton)
        view.addSubview(tableView)

        // 6) Turn off autoresizing masks
        addNewButton.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        // 7) Set up tableView delegates/dataSource, register cell
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true
        tableView.register(
            CustomChecklistMenuCell.self,
            forCellReuseIdentifier: "CustomChecklistMenuCell"
        )

        // 8) Constraints: button pinned to top, table pinned below it
        NSLayoutConstraint.activate([
            // “Add New Checklist +” button at very top (behind nav‐bar if opaque)
                addNewButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
                addNewButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                addNewButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // tableView sits directly under the button, fills remainder
            tableView.topAnchor.constraint(equalTo: addNewButton.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Force the nav bar to re‐layout (for theme changes)
        navigationController?.navigationBar.layoutIfNeeded()

        // Refresh the list of checklists each time
        checklists = CustomChecklistManager.shared.loadAll()
        tableView.reloadData()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Re‐apply background and nav‐bar theme
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        ThemeManager.apply(to: navigationController, traitCollection: traitCollection)

        // Re‐apply button color
        addNewButton.backgroundColor = ThemeManager.themeColor
        tableView.reloadData()
    }

    // MARK: - Actions

    @objc private func createNewChecklist() {
        // 1) Create a brand‐new, empty checklist
        let newChecklist = CustomChecklist(
            id: UUID(),
            title: "Untitled Checklist",
            sections: [
                ChecklistSection(title: "High Priority", items: []),
                ChecklistSection(title: "Medium Priority", items: []),
                ChecklistSection(title: "Low Priority", items: [])
            ]
        )

        // 2) Persist it
        CustomChecklistManager.shared.add(newChecklist)

        // 3) Push the editor so user can rename and add items
        let editorVC = CustomChecklistEditorViewController()
        editorVC.checklist = newChecklist
        navigationController?.pushViewController(editorVC, animated: true)
    }
    // MARK: - Share Checklist
        
        private func shareChecklist(_ checklist: CustomChecklist) {
            // 1) Convert checklist to JSON data
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            guard let jsonData = try? encoder.encode(checklist) else {
                showAlert(title: "Export Error", message: "Could not prepare checklist for sharing.")
                return
            }
            
            // 2) Create a temporary file with .shipchecklist extension
            let fileName = "\(checklist.title.replacingOccurrences(of: "/", with: "-")).shipchecklist"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            do {
                try jsonData.write(to: tempURL)
            } catch {
                showAlert(title: "Export Error", message: "Could not create checklist file: \(error.localizedDescription)")
                return
            }
            
            // 3) Present the share sheet
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            // For iPad - set the popover source
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = view
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            present(activityVC, animated: true)
        }
        
        private func showAlert(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return checklists.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let checklist = checklists[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "CustomChecklistMenuCell",
            for: indexPath
        ) as! CustomChecklistMenuCell

        cell.configure(with: checklist, traitCollection: self.traitCollection)
        cell.accessoryType = .disclosureIndicator

        // When pencil (edit) tapped, push editor
        cell.editTapped = { [weak self] in
            let editorVC = CustomChecklistEditorViewController()
            editorVC.checklist = checklist
            self?.navigationController?.pushViewController(editorVC, animated: true)
        }

        // Toggle “favorite” star
        cell.favoriteTapped = { [weak self] in
            var updated = checklist
            updated.isFavorite.toggle()
            CustomChecklistManager.shared.update(updated)
            self?.checklists[indexPath.row] = updated
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }

        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        let detailVC = ChecklistViewController()
        detailVC.customChecklist = checklists[indexPath.row]
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        
        // Share action (for exporting checklist to another pilot)
        let share = UIContextualAction(
            style: .normal, title: "Share"
        ) { [weak self] _, _, completion in
            guard let self = self else { return }
            let checklistToShare = self.checklists[indexPath.row]
            self.shareChecklist(checklistToShare)
            completion(true)
        }
        share.backgroundColor = ThemeManager.themeColor
        
        // Delete action
        let delete = UIContextualAction(
            style: .destructive, title: "Delete"
        ) { [weak self] _, _, completion in
            guard let self = self else { return }
            let removed = self.checklists.remove(at: indexPath.row)
            CustomChecklistManager.shared.delete(removed)
            tableView.deleteRows(at: [indexPath], with: .fade)
            completion(true)
        }
        
        return UISwipeActionsConfiguration(actions: [delete, share])
    }

    // Allow reordering
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(
        _ tableView: UITableView,
        moveRowAt sourceIndexPath: IndexPath,
        to destinationIndexPath: IndexPath
    ) {
        let moved = checklists.remove(at: sourceIndexPath.row)
        checklists.insert(moved, at: destinationIndexPath.row)
        CustomChecklistManager.shared.saveAll(checklists)
    }

    // MARK: - Drag & Drop

    func tableView(
        _ tableView: UITableView,
        itemsForBeginning session: UIDragSession,
        at indexPath: IndexPath
    ) -> [UIDragItem] {
        let checklist = checklists[indexPath.row]
        let provider = NSItemProvider(object: checklist.title as NSString)
        let item = UIDragItem(itemProvider: provider)
        item.localObject = checklist
        return [item]
    }

    func tableView(
        _ tableView: UITableView,
        performDropWith coordinator: UITableViewDropCoordinator
    ) {
        guard
          let first = coordinator.items.first,
          let sourceIdx = checklists.firstIndex(where: {
            $0.id == (first.dragItem.localObject as? CustomChecklist)?.id
          }),
          let dest   = coordinator.destinationIndexPath
        else { return }

        let moved = checklists.remove(at: sourceIdx)
        checklists.insert(moved, at: dest.row)
        tableView.reloadData()
        CustomChecklistManager.shared.saveAll(checklists)
    }

    func tableView(
        _ tableView: UITableView,
        dropSessionDidUpdate session: UIDropSession,
        withDestinationIndexPath dest: IndexPath?
    ) -> UITableViewDropProposal {
        return UITableViewDropProposal(
            operation: .move,
            intent: .insertAtDestinationIndexPath
        )
    }
}

