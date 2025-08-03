//
//  CustomChecklistListViewController.swift
//  Ship Pilot Checklists
//

import UIKit

class CustomChecklistListViewController: UIViewController,
                                         UITableViewDataSource,
                                         UITableViewDelegate,
                                         UITableViewDragDelegate,
                                         UITableViewDropDelegate,
                                         UIDocumentPickerDelegate {

    // MARK: - Data
    private var checklists: [CustomChecklist] = []

    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let bottomToolbar = UIToolbar()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

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
        
        // ADD THIS: Listen for import notifications
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(checklistImported),
                name: NSNotification.Name("ChecklistImported"),
                object: nil
            )

        // 5) Add subviews
        view.addSubview(tableView)
        view.addSubview(bottomToolbar)

        // 6) Turn off autoresizing masks
        tableView.translatesAutoresizingMaskIntoConstraints = false
        bottomToolbar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomToolbar.topAnchor),

            bottomToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomToolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

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

        // ✅ 8) Set up toolbar items
        setupToolbar()
    }
    @objc private func checklistImported() {
        // Reload the checklists and refresh the table
        checklists = CustomChecklistManager.shared.loadAll()
        tableView.reloadData()
    }
    private func setupToolbar() {
        ThemeManager.applyToolbarAppearance(bottomToolbar, trait: traitCollection)

        let newButton = UIBarButtonItem(
            title: "New Checklist",
            style: .plain,
            target: self,
            action: #selector(createNewChecklist)
        )

        let importButton = UIBarButtonItem(
            title: "Import .csv",
            style: .plain,
            target: self,
            action: #selector(importCSVButtonTapped)
        )

        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        bottomToolbar.items = [newButton, spacer, importButton]
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

        // Re-apply appearance for toolbar
        ThemeManager.applyToolbarAppearance(bottomToolbar, trait: traitCollection)

        // Refresh table view colors if needed
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
    
    @objc private func importCSVButtonTapped() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.commaSeparatedText], asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        
        // IMPORTANT: Force the document picker to match your app's night mode setting
        picker.overrideUserInterfaceStyle = UserDefaults.standard.bool(forKey: "nightMode") ? .dark : .light
        
        present(picker, animated: true)
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
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completionHandler in
            guard let self = self else {
                completionHandler(false)
                return
            }

            let checklist = self.checklists[indexPath.row]

            let alert = UIAlertController(
                title: "Delete Checklist",
                message: "Are you sure you want to delete \"\(checklist.title)\"?",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completionHandler(false)
            })

            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                self.checklists.remove(at: indexPath.row)
                CustomChecklistManager.shared.delete(checklist)
                tableView.deleteRows(at: [indexPath], with: .fade)
                completionHandler(true)
            })

            self.present(alert, animated: true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    func tableView(
        _ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {

        // Share action
        let share = UIContextualAction(
            style: .normal,
            title: "Share"
        ) { [weak self] _, _, completion in
            guard let self = self else { return }
            let checklistToShare = self.checklists[indexPath.row]
            self.shareChecklist(checklistToShare)
            completion(true)
        }

        share.backgroundColor = ThemeManager.themeColor

        return UISwipeActionsConfiguration(actions: [share])
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let checklist = checklists[indexPath.row]

        let checklistVC = ChecklistViewController() // Or whatever VC shows the checklist
        checklistVC.customChecklist = checklist     // Assuming this is how you pass it
        navigationController?.pushViewController(checklistVC, animated: true)
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
    // MARK: - UIDocumentPickerDelegate

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        print("📁 Document picker selected: \(url)")
        
        // The file is already in a temporary location accessible to our app
        // Just pass it directly to the import method
        DispatchQueue.main.async { [weak self] in
            // Get the scene delegate
            let sceneDelegate = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive })?
                .delegate as? UIWindowSceneDelegate
            
            if let sd = sceneDelegate as? SceneDelegate {
                // Call the import method directly with the URL
                sd.importChecklistFromCSV(url: url)
            } else {
                self?.showAlert(title: "Import Failed", message: "Unable to access the current scene.")
            }
        }
    }
}

