//
//  ChecklistMenuViewController.swift
//  Ship Pilot Checklists
//
//  This is the final, complete, and corrected version.
//

import UIKit

class ChecklistMenuViewController: UIViewController {

    let tableView = UITableView(frame: .zero, style: .insetGrouped)

    var emergencyChecklists: [ChecklistInfo] = []
    var standardChecklists:  [ChecklistInfo] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Included Checklists"
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        overrideUserInterfaceStyle = UserDefaults.standard.bool(forKey: "nightMode") ? .dark : .light
        setupTableView()
        loadChecklistsInBackground()
    }
    
    private func loadChecklistsInBackground() {
        guard emergencyChecklists.isEmpty && standardChecklists.isEmpty else { return }
        
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = ThemeManager.titleColor(for: traitCollection)
        indicator.center = view.center
        indicator.startAnimating()
        view.addSubview(indicator)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let allData = IncludedChecklists.all
            let emergency = allData.filter { $0.category == .emergency }
            let standard = allData.filter { $0.category == .standard }
            
            DispatchQueue.main.async {
                self.emergencyChecklists = emergency
                self.standardChecklists = standard
                self.tableView.reloadData()
                indicator.stopAnimating()
                indicator.removeFromSuperview()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.setNeedsLayout()
        // Reload data to reflect any favorite status changes made elsewhere
        tableView.reloadData()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        ThemeManager.apply(to: navigationController, traitCollection: traitCollection)
        tableView.reloadData()
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate  = self
        tableView.register(ChecklistMenuCell.self, forCellReuseIdentifier: "ChecklistMenuCell")

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: – TableView Delegate & DataSource

extension ChecklistMenuViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return emergencyChecklists.isEmpty ? nil : (section == 0 ? "Emergency" : "Routine")
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? emergencyChecklists.count : standardChecklists.count
    }

    private func checklistFor(indexPath: IndexPath) -> ChecklistInfo {
        return indexPath.section == 0 ? emergencyChecklists[indexPath.row] : standardChecklists[indexPath.row]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let checklist = checklistFor(indexPath: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChecklistMenuCell", for: indexPath) as! ChecklistMenuCell
        
        cell.configure(with: checklist, traitCollection: self.traitCollection)

        cell.favoriteTapped = {
            FavoritesManager.toggleFavorite(for: checklist.title)
            tableView.reloadRows(at: [indexPath], with: .none)
        }

        cell.addTapped = { [weak self] in
            let custom = checklist.convertToCustom()
            CustomChecklistManager.shared.add(custom)
            let editorVC = CustomChecklistEditorViewController()
            editorVC.checklist = custom
            self?.navigationController?.pushViewController(editorVC, animated: true)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedChecklist = checklistFor(indexPath: indexPath)
        let detailVC = ChecklistViewController()
        detailVC.checklist = selectedChecklist
        navigationController?.pushViewController(detailVC, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
