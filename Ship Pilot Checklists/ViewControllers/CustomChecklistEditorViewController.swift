//
//  CustomChecklistEditorViewController.swift
//  Ship Pilot Checklists
//

import UIKit

class CustomChecklistEditorViewController: UIViewController, UITextFieldDelegate {

    // The checklist we're editing (injected before push)
    var checklist: CustomChecklist!
    
    // Track if we have unsaved changes
    private var hasUnsavedChanges = false
    
    // Track the currently editing cell
    private weak var currentlyEditingCell: EditableChecklistCell?

    // MARK: – UI Elements

    private let titleField = UITextField()
    private let favoriteButton = UIButton(type: .system)
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // MARK: – Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1) Edge-to-edge under nav bar & home indicator
        edgesForExtendedLayout = [.all]
        extendedLayoutIncludesOpaqueBars = true

        // 2) Force day/night
        overrideUserInterfaceStyle = UserDefaults.standard.bool(forKey: "nightMode")
            ? .dark : .light

        // 3) Set nav title to current checklist title
        navigationItem.title = checklist.title

        // 4) Background
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)

        // 5) Build subviews
        setupTitleField()
        setupFavoriteButton()
        setupTableView()

        // 6) "Save" button on top right
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveChecklist)
        )

        // Wire up the text field delegate
        titleField.delegate = self

        // Tap anywhere to dismiss keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        // Add keyboard observers
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.layoutIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Check for unsaved changes
        if hasUnsavedChanges {
            showUnsavedChangesAlert()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Re-apply background & favorite icon tint
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        updateFavoriteIcon()
        ThemeManager.apply(to: navigationController, traitCollection: traitCollection)
        tableView.reloadData()
    }

    // MARK: – Keyboard Handling

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        
        UIView.animate(withDuration: duration) {
            self.tableView.contentInset.bottom = keyboardHeight
            self.tableView.scrollIndicatorInsets.bottom = keyboardHeight
            
            // Scroll to show the editing cell if needed
            if let cell = self.currentlyEditingCell,
               let indexPath = self.tableView.indexPath(for: cell) {
                self.tableView.scrollToRow(at: indexPath, at: .none, animated: true)
            }
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        
        UIView.animate(withDuration: duration) {
            self.tableView.contentInset.bottom = 0
            self.tableView.scrollIndicatorInsets.bottom = 0
        }
    }

    // MARK: – UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Prevent the space bar issue on iPad by ensuring proper focus
        textField.becomeFirstResponder()
    }

    // MARK: – Setup Title Text Field

    private func setupTitleField() {
        titleField.translatesAutoresizingMaskIntoConstraints = false
        titleField.borderStyle = .roundedRect
        titleField.placeholder = "Checklist Title"
        titleField.text = checklist.title
        titleField.font = .systemFont(ofSize: 24, weight: .bold)
        titleField.addTarget(self, action: #selector(titleDidChange(_:)), for: .editingChanged)
        titleField.autocorrectionType = .default
        titleField.autocapitalizationType = .sentences
        titleField.returnKeyType = .done

        view.addSubview(titleField)

        // Pin under safeArea (so it never hides under notch)
        NSLayoutConstraint.activate([
            titleField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            titleField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60),
            titleField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func titleDidChange(_ sender: UITextField) {
        // Keep navigationItem.title in sync as user types
        checklist.title = sender.text ?? ""
        navigationItem.title = checklist.title.isEmpty
            ? "Untitled Checklist"
            : checklist.title
        hasUnsavedChanges = true
    }

    // MARK: – Favorite (Star) Button

    private func setupFavoriteButton() {
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        updateFavoriteIcon()
        favoriteButton.addTarget(self, action: #selector(toggleFavorite), for: .touchUpInside)

        view.addSubview(favoriteButton)

        NSLayoutConstraint.activate([
            favoriteButton.centerYAnchor.constraint(equalTo: titleField.centerYAnchor),
            favoriteButton.leadingAnchor.constraint(equalTo: titleField.trailingAnchor, constant: 8),
            favoriteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            favoriteButton.widthAnchor.constraint(equalToConstant: 32),
            favoriteButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    @objc private func toggleFavorite() {
        checklist.isFavorite.toggle()
        updateFavoriteIcon()
        hasUnsavedChanges = true
    }

    private func updateFavoriteIcon() {
        let iconName = checklist.isFavorite ? "star.fill" : "star"
        favoriteButton.setImage(UIImage(systemName: iconName), for: .normal)
        favoriteButton.tintColor = ThemeManager.titleColor(for: traitCollection)
    }

    // MARK: – TableView (add/remove/reorder items only)

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true
        tableView.keyboardDismissMode = .interactive

        tableView.register(
            EditableChecklistCell.self,
            forCellReuseIdentifier: "EditableChecklistCell"
        )

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            // Table sits immediately below titleField
            tableView.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: – Save Checklist

    @objc private func saveChecklist() {
        // 1) Ensure title is not empty
        let trimmedTitle = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmedTitle.isEmpty else {
            showAlert("Missing Title", message: "Please enter a title before saving.")
            return
        }

        // 2) Persist updated title & items
        checklist.title = trimmedTitle
        CustomChecklistManager.shared.update(checklist)
        hasUnsavedChanges = false

        // 3) Pop back to the list (if present)
        if let nav = navigationController {
            if let existingList = nav.viewControllers
                .first(where: { $0 is CustomChecklistListViewController })
                    as? CustomChecklistListViewController
            {
                nav.popToViewController(existingList, animated: true)
                return
            }
            // Otherwise, pop to root and push a fresh list VC
            nav.popToRootViewController(animated: false)
            let listVC = CustomChecklistListViewController()
            nav.pushViewController(listVC, animated: true)
        } else {
            // If this were presented modally, just dismiss
            dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - Unsaved Changes Alert
    
    private func showUnsavedChangesAlert() {
        let alert = UIAlertController(
            title: "Unsaved Changes",
            message: "You have unsaved changes. Do you want to save before leaving?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            self.saveChecklist()
        })
        
        alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { _ in
            self.hasUnsavedChanges = false
            self.navigationController?.popViewController(animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }

    // MARK: – Helper Alert

    private func showAlert(_ title: String, message: String) {
        let ac = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}

// MARK: — UITableViewDataSource & UITableViewDelegate

extension CustomChecklistEditorViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return checklist.sections.count
    }

    func tableView(_ tableView: UITableView,
                   titleForHeaderInSection section: Int) -> String? {
        return checklist.sections[section].title.uppercased()
    }

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        // +1 for the "+" row that adds a new item to this section
        return checklist.sections[section].items.count + 1
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let isAddRow = indexPath.row == checklist.sections[indexPath.section].items.count

        // The "+" row (to append a new ChecklistItem)
        if isAddRow {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = "+"
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.font = .systemFont(ofSize: 24, weight: .bold)
            cell.textLabel?.textColor = ThemeManager.titleColor(for: traitCollection)
            return cell
        }

        // Otherwise, show an existing item in an EditableChecklistCell
        let item = checklist.sections[indexPath.section].items[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "EditableChecklistCell",
            for: indexPath
        ) as! EditableChecklistCell

        cell.configure(with: item)
        cell.showsReorderControl = false

        // When cell begins editing, track it
        cell.editingBegan = { [weak self] in
            self?.currentlyEditingCell = cell
        }
        
        // When user presses return, handle it
        cell.returnPressed = { [weak self] in
            guard let self = self else { return }
            
            // Find the current index path
            guard let currentIndexPath = self.tableView.indexPath(for: cell) else { return }
            
            // If this is the last item in the section, add a new one
            let section = currentIndexPath.section
            let isLastItem = currentIndexPath.row == self.checklist.sections[section].items.count - 1
            
            if isLastItem {
                // Add new item
                self.checklist.sections[section].items.append(
                    ChecklistItem(title: "", isChecked: false, timestamp: nil, quickNote: nil)
                )
                
                // Insert new row
                let newIndex = IndexPath(row: currentIndexPath.row + 1, section: section)
                self.tableView.insertRows(at: [newIndex], with: .automatic)
                
                // Focus on the new cell after a slight delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if let newCell = self.tableView.cellForRow(at: newIndex) as? EditableChecklistCell {
                        newCell.beginEditing()
                    }
                }
            } else {
                // Just move to the next item
                let nextIndex = IndexPath(row: currentIndexPath.row + 1, section: section)
                if let nextCell = self.tableView.cellForRow(at: nextIndex) as? EditableChecklistCell {
                    nextCell.beginEditing()
                } else {
                    // Dismiss keyboard if no next cell
                    cell.endEditing()
                }
            }
        }

        // If user edits text, update our in-memory model
        cell.textChanged = { [weak self] newText in
            guard let self = self,
                  let currentIndexPath = self.tableView.indexPath(for: cell),
                  currentIndexPath.section < self.checklist.sections.count,
                  currentIndexPath.row < self.checklist.sections[currentIndexPath.section].items.count else {
                return
            }
            self.checklist.sections[currentIndexPath.section].items[currentIndexPath.row].title = newText
            self.hasUnsavedChanges = true
        }

        // If user taps delete, remove that item
        cell.deleteTapped = { [weak self] in
            guard let self = self else { return }
            self.checklist.sections[indexPath.section]
                .items.remove(at: indexPath.row)
            self.hasUnsavedChanges = true
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }

        return cell
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let isAddRow = indexPath.row == checklist.sections[section].items.count
        if isAddRow {
            // 1) Append a brand-new empty ChecklistItem
            checklist.sections[section].items.append(
                ChecklistItem(title: "", isChecked: false, timestamp: nil, quickNote: nil)
            )

            // 2) Insert new row at the end of this section
            let newIndex = IndexPath(row: checklist.sections[section].items.count - 1, section: section)
            tableView.insertRows(at: [newIndex], with: .automatic)
            hasUnsavedChanges = true
            
            // 3) Auto-focus on the new cell
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let newCell = tableView.cellForRow(at: newIndex) as? EditableChecklistCell {
                    newCell.beginEditing()
                }
            }
        }
    }

    func tableView(_ tableView: UITableView,
                   canMoveRowAt indexPath: IndexPath) -> Bool {
        // Only existing items (not the "+" row) can be reordered
        return indexPath.row < checklist.sections[indexPath.section].items.count
    }

    func tableView(_ tableView: UITableView,
                   editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
}

// MARK: — Drag & Drop

extension CustomChecklistEditorViewController: UITableViewDragDelegate, UITableViewDropDelegate {

    func tableView(_ tableView: UITableView,
                   itemsForBeginning session: UIDragSession,
                   at indexPath: IndexPath) -> [UIDragItem] {
        guard indexPath.row < checklist.sections[indexPath.section].items.count else {
            return []
        }
        let draggedItem = checklist.sections[indexPath.section].items[indexPath.row]
        let provider = NSItemProvider(object: draggedItem.title as NSString)
        let dragItem = UIDragItem(itemProvider: provider)
        dragItem.localObject = (indexPath, draggedItem)
        return [dragItem]
    }

    func tableView(_ tableView: UITableView,
                   performDropWith coordinator: UITableViewDropCoordinator) {
        guard
            let item                   = coordinator.items.first,
            let (srcIndexPath, model)  = item.dragItem.localObject as? (IndexPath, ChecklistItem),
            let destIndexPath          = coordinator.destinationIndexPath
        else { return }

        let isAddRow = destIndexPath.row > checklist.sections[destIndexPath.section].items.count
        if isAddRow { return }

        tableView.performBatchUpdates {
            // Remove from source
            checklist.sections[srcIndexPath.section].items.remove(at: srcIndexPath.row)
            // Insert at destination
            checklist.sections[destIndexPath.section].items.insert(model, at: destIndexPath.row)

            if srcIndexPath.section == destIndexPath.section {
                tableView.moveRow(at: srcIndexPath, to: destIndexPath)
            } else {
                tableView.deleteRows(at: [srcIndexPath], with: .automatic)
                tableView.insertRows(at: [destIndexPath], with: .automatic)
            }
            hasUnsavedChanges = true
        }
    }

    func tableView(_ tableView: UITableView,
                   dropSessionDidUpdate session: UIDropSession,
                   withDestinationIndexPath dest: IndexPath?) -> UITableViewDropProposal {
        return UITableViewDropProposal(
            operation: .move,
            intent: .insertAtDestinationIndexPath
        )
    }
}
