import UIKit
import QuickLook

class SavedFilesViewController: UIViewController {
    private var fileURLs: [URL] = []
    private var sortOption: SortOption = .name {
        didSet { sortFileURLs() }
    }

    private enum SortOption: Int {
        case name = 0
        case date = 1
    }

    private let tableView = UITableView()
    private let previewController = QLPreviewController()
    private let sortControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Sort by Name", "Sort by Date"])
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Saved Files"
        view.backgroundColor = .systemBackground
        setupSortControl()
        setupTableView()
        loadFileURLs()
    }

    private func setupSortControl() {
        sortControl.addTarget(self, action: #selector(sortOptionChanged), for: .valueChanged)
        view.addSubview(sortControl)

        NSLayoutConstraint.activate([
            sortControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            sortControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            sortControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FileCell")
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: sortControl.bottomAnchor, constant: 10),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func loadFileURLs() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: documentsURL,
                includingPropertiesForKeys: [.contentModificationDateKey, .isDirectoryKey]
            )

            fileURLs = contents.filter { url in
                let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                return !isDirectory || url.lastPathComponent != "Photos"
            }

            sortFileURLs()
        } catch {
            print("❌ Failed to list files: \(error)")
        }
    }

    private func sortFileURLs() {
        switch sortOption {
        case .name:
            fileURLs.sort { $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased() }
        case .date:
            fileURLs.sort {
                let date1 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let date2 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return date1 > date2
            }
        }
        tableView.reloadData()
    }

    @objc private func sortOptionChanged() {
        sortOption = SortOption(rawValue: sortControl.selectedSegmentIndex) ?? .name
    }
}

// MARK: - TableView DataSource & Delegate

extension SavedFilesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileURLs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath)
        cell.textLabel?.text = fileURLs[indexPath.row].lastPathComponent
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fileURL = fileURLs[indexPath.row]

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            showAlert(title: "File Not Found", message: "This file no longer exists.")
            return
        }

        previewController.dataSource = self
        previewController.currentPreviewItemIndex = indexPath.row
        navigationController?.pushViewController(previewController, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let fileURL = fileURLs[indexPath.row]

        let shareAction = UIContextualAction(style: .normal, title: "Share") { _, _, completion in
            let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = self.view
                popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            self.present(activityVC, animated: true)
            completion(true)
        }
        shareAction.backgroundColor = .systemBlue

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
            do {
                try FileManager.default.removeItem(at: fileURL)
                self.fileURLs.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                completion(true)
            } catch {
                print("❌ Failed to delete file: \(error)")
                completion(false)
            }
        }

        return UISwipeActionsConfiguration(actions: [deleteAction, shareAction])
    }
}

// MARK: - Quick Look Preview

extension SavedFilesViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return fileURLs.count
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return fileURLs[index] as NSURL
    }
}

// MARK: - Helper

private extension SavedFilesViewController {
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
