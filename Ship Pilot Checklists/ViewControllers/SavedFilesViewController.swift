import UIKit
import QuickLook
import AVFoundation

class SavedFilesViewController: UIViewController {
    private var fileURLs: [URL] = []
    private var filteredURLs: [URL] = []
    
    private var sortOption: SortOption = .date {
        didSet { sortAndFilterFileURLs() }
    }
    
    private var filterOption: FilterOption = .all {
        didSet { sortAndFilterFileURLs() }
    }

    private enum SortOption: Int {
        case name = 0
        case date = 1
    }
    
    private enum FilterOption: Int {
        case all = 0
        case pdf = 1
        case audio = 2
    }

    private let tableView = UITableView()
    private let previewController = QLPreviewController()
    private let noFilesLabel = UILabel()
    
    private let sortControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Sort by Name", "Sort by Date"])
        control.selectedSegmentIndex = 1 // Default to date sorting
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private let filterControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["All Files", "PDFs", "Audio"])
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private let refreshButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .refresh, target: nil, action: #selector(refreshFiles))
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Saved Files"
        view.backgroundColor = .systemBackground
        setupSortAndFilterControls()
        setupTableView()
        setupNoFilesLabel()
        setupRefreshButton()
        loadFileURLs()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh files each time the view appears
        loadFileURLs()
    }
    
    private func setupSortAndFilterControls() {
        let controlsStackView = UIStackView()
        controlsStackView.axis = .vertical
        controlsStackView.spacing = 8
        controlsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        sortControl.addTarget(self, action: #selector(sortOptionChanged), for: .valueChanged)
        filterControl.addTarget(self, action: #selector(filterOptionChanged), for: .valueChanged)
        
        controlsStackView.addArrangedSubview(sortControl)
        controlsStackView.addArrangedSubview(filterControl)
        
        view.addSubview(controlsStackView)

        NSLayoutConstraint.activate([
            controlsStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            controlsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            controlsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(SavedFileCell.self, forCellReuseIdentifier: "FileCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 72
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: filterControl.bottomAnchor, constant: 16),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupNoFilesLabel() {
        noFilesLabel.translatesAutoresizingMaskIntoConstraints = false
        noFilesLabel.text = "No files found"
        noFilesLabel.textAlignment = .center
        noFilesLabel.textColor = .secondaryLabel
        noFilesLabel.font = .systemFont(ofSize: 18)
        noFilesLabel.isHidden = true
        
        view.addSubview(noFilesLabel)
        
        NSLayoutConstraint.activate([
            noFilesLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            noFilesLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
    }
    
    private func setupRefreshButton() {
        refreshButton.target = self
        refreshButton.action = #selector(refreshFiles)
        navigationItem.rightBarButtonItem = refreshButton
    }

    @objc private func refreshFiles() {
        loadFileURLs()
    }

    private func loadFileURLs() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: documentsURL,
                includingPropertiesForKeys: [.contentModificationDateKey, .isDirectoryKey, .fileSizeKey],
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            )

            fileURLs = contents.filter { url in
                // Filter out directories and system files
                let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                if isDirectory && url.lastPathComponent != "Photos" {
                    return false
                }
                
                // Only include PDFs and audio files
                let fileExtension = url.pathExtension.lowercased()
                return fileExtension == "pdf" || fileExtension == "m4a" || fileExtension == "mp4"
            }

            sortAndFilterFileURLs()
        } catch {
            print("❌ Failed to list files: \(error)")
            showAlert(title: "Error", message: "Failed to load files: \(error.localizedDescription)")
        }
    }

    private func sortAndFilterFileURLs() {
        // First filter
        switch filterOption {
        case .all:
            filteredURLs = fileURLs
        case .pdf:
            filteredURLs = fileURLs.filter { $0.pathExtension.lowercased() == "pdf" }
        case .audio:
            filteredURLs = fileURLs.filter {
                let ext = $0.pathExtension.lowercased()
                return ext == "m4a" || ext == "mp4"
            }
        }
        
        // Then sort
        switch sortOption {
        case .name:
            filteredURLs.sort { $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased() }
        case .date:
            filteredURLs.sort {
                let date1 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let date2 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return date1 > date2 // Most recent first
            }
        }
        
        // Update UI
        tableView.reloadData()
        noFilesLabel.isHidden = !filteredURLs.isEmpty
    }

    @objc private func sortOptionChanged() {
        sortOption = SortOption(rawValue: sortControl.selectedSegmentIndex) ?? .date
    }
    
    @objc private func filterOptionChanged() {
        filterOption = FilterOption(rawValue: filterControl.selectedSegmentIndex) ?? .all
    }
    
    // Helper function to format file size
    private func formatFileSize(_ size: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
    
    // Helper function to extract file information from name
    private func extractFileInfo(from url: URL) -> (name: String, date: String, vessel: String?, type: String) {
        let filename = url.deletingPathExtension().lastPathComponent
        let components = filename.split(separator: "_")
        
        let fileExtension = url.pathExtension.lowercased()
        let fileType = fileExtension == "pdf" ? "PDF" :
                      (fileExtension == "m4a" || fileExtension == "mp4") ? "Audio" : "File"
        
        // Attempt to parse standardized naming format: Checklistname_Date_VesselName
        if components.count >= 3 {
            let name = String(components[0])
            let date = String(components[1])
            
            // For voice memo files that end with AudioRecording, extract the vessel name
            if components.last == "AudioRecording" && components.count >= 4 {
                let vessel = String(components[2])
                return (name: name, date: date, vessel: vessel, type: fileType)
            } else {
                // For PDFs and other files
                let vessel = String(components[2])
                return (name: name, date: date, vessel: vessel, type: fileType)
            }
        }
        
        // Fall back to basic info for files not following the format
        return (name: url.deletingPathExtension().lastPathComponent,
                date: "",
                vessel: nil,
                type: fileType)
    }
}

// MARK: - TableView DataSource & Delegate

extension SavedFilesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredURLs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath) as! SavedFileCell
        
        let fileURL = filteredURLs[indexPath.row]
        let fileInfo = extractFileInfo(from: fileURL)
        
        // Get file size and date
        let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        let fileDate = (try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        // Configure the cell
        cell.configure(
            title: fileURL.lastPathComponent,
            subtitle: fileInfo.vessel != nil ? "Vessel: \(fileInfo.vessel!)" : "",
            fileType: fileInfo.type,
            fileSize: formatFileSize(fileSize),
            fileDate: dateFormatter.string(from: fileDate)
        )
        
        return cell
    }

    // Replace the existing swipe action method with these two methods

    // MARK: - TableView Swipe Actions

    // Left swipe for Delete
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let fileURL = filteredURLs[indexPath.row]

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
            // Show confirmation dialog first
            let alert = UIAlertController(
                title: "Delete File",
                message: "Are you sure you want to delete this file? This cannot be undone.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completion(false)
            })
            
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                do {
                    try FileManager.default.removeItem(at: fileURL)
                    self.fileURLs.removeAll { $0 == fileURL }
                    self.sortAndFilterFileURLs() // This will refresh the table
                    completion(true)
                } catch {
                    print("❌ Failed to delete file: \(error)")
                    self.showAlert(title: "Delete Failed", message: error.localizedDescription)
                    completion(false)
                }
            })
            
            self.present(alert, animated: true)
        }
        deleteAction.backgroundColor = .systemRed
        deleteAction.image = UIImage(systemName: "trash")

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    // Right swipe for Share
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let fileURL = filteredURLs[indexPath.row]

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
        shareAction.image = UIImage(systemName: "square.and.arrow.up")

        return UISwipeActionsConfiguration(actions: [shareAction])
    }
}

// MARK: - Quick Look Preview

extension SavedFilesViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return filteredURLs.count
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return filteredURLs[index] as NSURL
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

// MARK: - Custom File Cell

class SavedFileCell: UITableViewCell {
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let metadataLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        accessoryType = .disclosureIndicator
        
        // Configure icon
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .systemBlue
        
        // Configure labels
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.numberOfLines = 1
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 1
        
        metadataLabel.translatesAutoresizingMaskIntoConstraints = false
        metadataLabel.font = .systemFont(ofSize: 12)
        metadataLabel.textColor = .tertiaryLabel
        metadataLabel.numberOfLines = 1
        
        // Add subviews
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(metadataLabel)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            
            metadataLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metadataLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            metadataLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 2),
            metadataLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    func configure(title: String, subtitle: String, fileType: String, fileSize: String, fileDate: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        metadataLabel.text = "\(fileType) • \(fileSize) • \(fileDate)"
        
        // Set appropriate icon based on file type
        let iconName: String
        if fileType == "PDF" {
            iconName = "doc.text"
        } else if fileType == "Audio" {
            iconName = "mic"
        } else {
            iconName = "doc"
        }
        
        iconImageView.image = UIImage(systemName: iconName)
    }
}
