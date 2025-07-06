// ChecklistViewController.swift
// Ship Pilot Checklists

// MARK: — Signature Drawing View Controller
class SignatureViewController: UIViewController {
    private let canvasView = UIView()
    private var currentPath = UIBezierPath()
    private var paths: [UIBezierPath] = []
    private let strokeColor = UIColor.black
    private let strokeWidth: CGFloat = 3.0
    
    var onSignatureComplete: ((UIImage?) -> Void)?
    var signatureFor: String = "Signature"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "\(signatureFor) Signature"
        setupNavigationButtons()
        setupCanvas()
    }
    
    private func setupNavigationButtons() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(doneTapped)
        )
    }
    
    private func setupCanvas() {
        // Instructions label
        let instructionLabel = UILabel()
        instructionLabel.text = "Please sign with your finger in the box below"
        instructionLabel.textAlignment = .center
        instructionLabel.font = .systemFont(ofSize: 16)
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Canvas setup
        canvasView.backgroundColor = .white
        canvasView.layer.borderColor = UIColor.lightGray.cgColor
        canvasView.layer.borderWidth = 2.0
        canvasView.layer.cornerRadius = 8
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        
        // Clear button
        let clearButton = UIButton(type: .system)
        clearButton.setTitle("Clear", for: .normal)
        clearButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        clearButton.addTarget(self, action: #selector(clearSignature), for: .touchUpInside)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(instructionLabel)
        view.addSubview(canvasView)
        view.addSubview(clearButton)
        
        NSLayoutConstraint.activate([
            instructionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            canvasView.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 30),
            canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            canvasView.heightAnchor.constraint(equalToConstant: 200),
            
            clearButton.topAnchor.constraint(equalTo: canvasView.bottomAnchor, constant: 20),
            clearButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: canvasView)
        guard canvasView.bounds.contains(point) else { return }
        
        currentPath = UIBezierPath()
        currentPath.lineWidth = strokeWidth
        currentPath.lineCapStyle = .round
        currentPath.lineJoinStyle = .round
        currentPath.move(to: point)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: canvasView)
        guard canvasView.bounds.contains(point) else { return }
        
        currentPath.addLine(to: point)
        drawPaths()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !currentPath.isEmpty {
            paths.append(currentPath)
        }
        drawPaths()
    }
    
    private func drawPaths() {
        canvasView.layer.sublayers?.removeAll()
        
        let shapeLayer = CAShapeLayer()
        let combinedPath = UIBezierPath()
        
        for path in paths {
            combinedPath.append(path)
        }
        combinedPath.append(currentPath)
        
        shapeLayer.path = combinedPath.cgPath
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = strokeWidth
        shapeLayer.lineCap = .round
        shapeLayer.lineJoin = .round
        
        canvasView.layer.addSublayer(shapeLayer)
    }
    
    @objc private func clearSignature() {
        paths.removeAll()
        currentPath = UIBezierPath()
        canvasView.layer.sublayers?.removeAll()
    }
    
    @objc private func cancelTapped() {
        onSignatureComplete?(nil)
    }
    
    @objc private func doneTapped() {
        if paths.isEmpty {
            let alert = UIAlertController(
                title: "No Signature",
                message: "Please draw your signature before tapping Done.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let signatureImage = captureSignature()
        onSignatureComplete?(signatureImage)
    }
    
    
    private func captureSignature() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(canvasView.bounds.size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        UIColor.white.setFill()
        UIRectFill(canvasView.bounds)
        
        strokeColor.setStroke()
        for path in paths {
            path.lineWidth = strokeWidth
            path.stroke()
        }
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
}
import UIKit
import AVFoundation
import CoreLocation
import MessageUI
import Photos
import PhotosUI


class ChecklistViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate, MFMessageComposeViewControllerDelegate, ContactSelectionDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate, UIDocumentPickerDelegate {

    // MARK: — Data

    /// Either a built-in checklist or a custom one
    var checklist: ChecklistInfo?
    var customChecklist: CustomChecklist?
    private var expandedSections = Set<Int>()
    // Store signature images temporarily
    private var pilotSignatureImage: UIImage?
    private var captainName: String?
    private var captainSignatureImage: UIImage?
    private var pendingVesselName: String?
    private var needsCaptainSignature: Bool = false

    /// Cache for tide & wind data
    private var lastFetchedTideLines: [String]?
    private var lastFetchedWindLines: [String]?
    private var lastFetchedTideStationName: String?
    private var lastFetchedWindLocationName: String?

    // MARK: — UI Elements

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let notesTextView = UITextView()
    private var emergencyButton: UIBarButtonItem!
    private var locationButton: UIBarButtonItem!
    private var tideButton: UIBarButtonItem!
    private var windButton: UIBarButtonItem!
    private var micButton: UIBarButtonItem!
    private var exportButton: UIBarButtonItem!
    private var clearButton:   UIBarButtonItem!

    // MARK: — Recording

    private var audioRecorder: AVAudioRecorder?
    private var isRecording = false
    private var recordingStartTime: Date?
    private var recordingTimer: Timer?

    // MARK: — Location
    
    private var isSearchingForGPS = false
    private let locationManager = CLLocationManager()
    private var latestLocation: CLLocation?           // store most recent location
    private var hasAddedLocationToNotes = false

    // MARK: — Helpers
    private func updateNotesTextViewTheme() {
        if notesTextView.text == "Notes..." {
            notesTextView.textColor = .secondaryLabel
        } else {
            notesTextView.textColor = ThemeManager.titleColor(for: traitCollection)
        }
        notesTextView.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
    }

    /// Builds a unique key for storing a built-in item’s quick note.
    private func builtInQuickNoteKey(for indexPath: IndexPath) -> String {
        guard let title = checklist?.title else { return "quickNote_unknown" }
        return "quickNote_builtin_\(title)_s\(indexPath.section)_r\(indexPath.row)"
    }

    private var pilotName: String {
        UserDefaults.standard.string(forKey: "pilotName") ?? ""
    }

    private func loadContacts() -> [EmergencyContact] {
        guard let data = UserDefaults.standard.data(forKey: "emergencyContacts"),
              let contacts = try? JSONDecoder().decode([EmergencyContact].self, from: data)
        else { return [] }
        return contacts
    }

    /// A unique UserDefaults key for this checklist’s Notes
    private var notesKey: String {
        if let c = customChecklist {
            return "notes_\(c.id.uuidString)"
        } else if let c = checklist {
            return "notes_builtin_\(c.title)"
        } else {
            return "notes_unknown"
        }
    }

    /// Store the IndexPath of the cell whose camera was tapped
    private var pendingPhotoIndexPath: IndexPath?
    private var notesContainerView = UIView()
    private var notesToggleButton = UIButton(type: .system)
    private var notesHeightConstraint: NSLayoutConstraint!
    private var isNotesCollapsed = false
    private let collapsedNotesHeight: CGFloat = 44
    private let expandedNotesHeight: CGFloat = 180

    // MARK: — Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Register both of our new cell types
        tableView.register(ChecklistCell.self, forCellReuseIdentifier: "ChecklistCell")

        // 1) Force day/night per user preference
        overrideUserInterfaceStyle = UserDefaults.standard.bool(forKey: "nightMode") ? .dark : .light

        // 2) Title and background
        title = checklist?.title ?? customChecklist?.title ?? "Checklist"
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)

        // 3) Location permission with GPS optimization
        setupLocationManager()

        // 4) Add Notes subview BEFORE the tableView, so constraints won’t crash
        setupNotesField()
        setupTableView()

        // 5) Install toolbar items (including tide+wind+export)
        setupToolbar()

        // 6) Tap to dismiss keyboard
        installDismissKeyboardGesture()

        // 7) Reload any saved Notes text for this checklist
        let saved = UserDefaults.standard.string(forKey: notesKey)
        notesTextView.text = saved ?? "Notes..."
        notesTextView.textColor = notesTextView.text == "Notes..." ? .secondaryLabel : ThemeManager.titleColor(for: traitCollection)

        // 8) Allow table rows to size themselves to content
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableView.automaticDimension
        // Make all sections start expanded by default
        for i in 0..<(checklist?.sections.count ?? customChecklist?.sections.count ?? 0) {
            expandedSections.insert(i)
        }
        loadBuiltInChecklistState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.layoutIfNeeded()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation // GPS-level accuracy
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.requestWhenInUseAuthorization()
    }
    
    
    // MARK: — Trait Collection Changes (Dark/Light Mode)

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Create a "fake" trait collection that reflects our app's night mode setting, not the system's
        let isAppInNightMode = UserDefaults.standard.bool(forKey: "nightMode")
        let fakeTraitCollection = UITraitCollection(userInterfaceStyle: isAppInNightMode ? .dark : .light)

        // Re-theme backgrounds using our app's setting
        view.backgroundColor = ThemeManager.backgroundColor(for: fakeTraitCollection)
        tableView.backgroundColor = ThemeManager.backgroundColor(for: fakeTraitCollection)

        // Re-theme toolbar items using our app's setting
        let tint = isRecording ? UIColor.systemRed : ThemeManager.titleColor(for: fakeTraitCollection)
        
        // Safely update toolbar items only if they're not nil
        micButton?.tintColor = tint
        locationButton?.tintColor = ThemeManager.titleColor(for: fakeTraitCollection)
        tideButton?.tintColor = ThemeManager.titleColor(for: fakeTraitCollection)
        windButton?.tintColor = ThemeManager.titleColor(for: fakeTraitCollection)
        emergencyButton?.tintColor = ThemeManager.titleColor(for: fakeTraitCollection)
        exportButton?.tintColor = ThemeManager.titleColor(for: fakeTraitCollection)
        clearButton?.tintColor = ThemeManager.titleColor(for: fakeTraitCollection)

        // Update notes field theme using our app's setting
        if notesTextView.text == "Notes..." {
            notesTextView.textColor = .secondaryLabel
        } else {
            notesTextView.textColor = ThemeManager.titleColor(for: fakeTraitCollection)
        }
        notesTextView.backgroundColor = ThemeManager.backgroundColor(for: fakeTraitCollection)
        // Update toggle button color
        notesToggleButton.tintColor = ThemeManager.titleColor(for: fakeTraitCollection)

        // Refresh checkbox rows
        tableView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Save whatever is currently in Notes (even if it’s “Notes...”)
        UserDefaults.standard.setValue(notesTextView.text, forKey: notesKey)
        if checklist != nil {
            saveBuiltInChecklistState()
        }
    }

    // MARK: — Setup Notes Field

    private func setupNotesField() {
        // Container view for notes
        notesContainerView.translatesAutoresizingMaskIntoConstraints = false
        notesContainerView.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        view.addSubview(notesContainerView)
        
        // Toggle button
        notesToggleButton.translatesAutoresizingMaskIntoConstraints = false
        notesToggleButton.setTitle("Notes", for: .normal)
        notesToggleButton.setImage(UIImage(systemName: "chevron.up"), for: .normal)
        notesToggleButton.contentHorizontalAlignment = .left
        notesToggleButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        notesToggleButton.tintColor = ThemeManager.titleColor(for: traitCollection)
        notesToggleButton.addTarget(self, action: #selector(toggleNotes), for: .touchUpInside)
        notesContainerView.addSubview(notesToggleButton)
        
        // Notes text view
        notesTextView.translatesAutoresizingMaskIntoConstraints = false
        notesTextView.font = .systemFont(ofSize: 16)
        notesTextView.layer.borderWidth = 1
        notesTextView.layer.cornerRadius = 8
        notesTextView.layer.borderColor = UIColor.lightGray.cgColor
        notesTextView.delegate = self
        notesTextView.text = "Notes..."
        notesTextView.textColor = .secondaryLabel
        notesTextView.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        
        // Add toolbar with Done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        doneButton.tintColor = ThemeManager.titleColor(for: traitCollection)
        toolbar.items = [flexSpace, doneButton]
        notesTextView.inputAccessoryView = toolbar
        
        notesContainerView.addSubview(notesTextView)
        
        // Create height constraint for animation
        notesHeightConstraint = notesContainerView.heightAnchor.constraint(equalToConstant: expandedNotesHeight + 44)
        
        NSLayoutConstraint.activate([
            // Container constraints
            notesContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            notesContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            notesContainerView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            notesHeightConstraint,
            
            // Toggle button constraints
            notesToggleButton.topAnchor.constraint(equalTo: notesContainerView.topAnchor, constant: 8),
            notesToggleButton.leadingAnchor.constraint(equalTo: notesContainerView.leadingAnchor, constant: 16),
            notesToggleButton.trailingAnchor.constraint(equalTo: notesContainerView.trailingAnchor, constant: -16),
            notesToggleButton.heightAnchor.constraint(equalToConstant: 28),
            
            // Text view constraints
            notesTextView.topAnchor.constraint(equalTo: notesToggleButton.bottomAnchor, constant: 8),
            notesTextView.leadingAnchor.constraint(equalTo: notesContainerView.leadingAnchor, constant: 16),
            notesTextView.trailingAnchor.constraint(equalTo: notesContainerView.trailingAnchor, constant: -16),
            notesTextView.bottomAnchor.constraint(equalTo: notesContainerView.bottomAnchor, constant: -8)
        ])
    }
    @objc private func toggleNotes() {
        isNotesCollapsed.toggle()
        
        UIView.animate(withDuration: 0.3) {
            if self.isNotesCollapsed {
                self.notesHeightConstraint.constant = self.collapsedNotesHeight
                self.notesToggleButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
                self.notesTextView.alpha = 0
            } else {
                self.notesHeightConstraint.constant = self.expandedNotesHeight + 44
                self.notesToggleButton.setImage(UIImage(systemName: "chevron.up"), for: .normal)
                self.notesTextView.alpha = 1
            }
            self.view.layoutIfNeeded()
        }
        
        // Dismiss keyboard when collapsing
        if isNotesCollapsed {
            notesTextView.resignFirstResponder()
        }
    }
    // MARK: — Setup TableView

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(ChecklistCell.self, forCellReuseIdentifier: "ChecklistCell")

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: notesContainerView.topAnchor, constant: -8)
        ])

        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
    }

    // MARK: — Setup Toolbar

    private func setupToolbar() {
        emergencyButton = UIBarButtonItem(
            image: UIImage(systemName: "text.bubble"),
            style: .plain,
            target: self,
            action: #selector(emergencyTapped)
        )
        locationButton = UIBarButtonItem(
            image: UIImage(systemName: "globe"),
            style: .plain,
            target: self,
            action: #selector(addLocationToNotes)
        )
        tideButton = UIBarButtonItem(
            image: UIImage(systemName: "water.waves.and.arrow.trianglehead.up"),
            style: .plain,
            target: self,
            action: #selector(fetchAndAppendTide)
        )
        windButton = UIBarButtonItem(
            image: UIImage(systemName: "wind"),
            style: .plain,
            target: self,
            action: #selector(fetchAndAppendWind)
        )
        micButton = UIBarButtonItem(
            image: UIImage(systemName: "mic"),
            style: .plain,
            target: self,
            action: #selector(toggleRecording)
        )
        exportButton = UIBarButtonItem(
            image: UIImage(systemName: "text.document"),
            style: .plain,
            target: self,
            action: #selector(confirmGeneratePDF)
        )
        clearButton = UIBarButtonItem(
        image: UIImage(systemName: "eraser"),
        style: .plain,
        target: self,
        action: #selector(promptClearChecklist)
        )

        [emergencyButton, locationButton, tideButton, windButton, micButton, exportButton, clearButton].forEach {
                    $0?.tintColor = ThemeManager.titleColor(for: traitCollection)
                }

        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                       target: nil,
                                       action: nil)
        toolbarItems = [
            emergencyButton,
            locationButton,
            tideButton,
            windButton,
            micButton,
            flexible,
            exportButton,
            clearButton
        ]
        navigationController?.isToolbarHidden = false
    }

    // MARK: — Dismiss Keyboard Gesture

    private func installDismissKeyboardGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: — Emergency Flow

    @objc private func emergencyTapped() {
        if pilotName.trimmingCharacters(in: .whitespaces).isEmpty {
            showAlert(title: "Name Missing",
                      message: "Please enter your name in Settings before sending an emergency text.")
            return
        }
        let allContacts = loadContacts()
        guard !allContacts.isEmpty else {
            showAlert(title: "No Emergency Contacts",
                      message: "Please add contacts in Settings first.")
            return
        }
        
        // Check if location/tide/wind data is missing
        var missingData: [String] = []
        if latestLocation == nil {
            missingData.append("GPS location (press globe button)")
        }
        if lastFetchedTideLines == nil {
            missingData.append("Tide data (press water/arrow button)")
        }
        if lastFetchedWindLines == nil {
            missingData.append("Wind data (press wind button)")
        }
        
        if !missingData.isEmpty {
            let message = "Your emergency SMS will be more helpful with:\n\n" + missingData.joined(separator: "\n") + "\n\nWould you like to add this data first?"
            
            let alert = UIAlertController(
                title: "Enhance Emergency SMS",
                message: message,
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Add Data First", style: .default) { _ in
                // Could potentially auto-trigger the first missing data fetch here
                if self.latestLocation == nil {
                    self.addLocationToNotes()
                }
            })
            
            alert.addAction(UIAlertAction(title: "Send Without Data", style: .cancel) { _ in
                self.proceedWithEmergencyContacts()
            })
            
            present(alert, animated: true)
        } else {
            proceedWithEmergencyContacts()
        }
    }
    private func proceedWithEmergencyContacts() {
        let allContacts = loadContacts()
        let picker = ContactSelectionViewController(style: .insetGrouped)
        picker.contacts = allContacts
        picker.delegate = self
        let nav = UINavigationController(rootViewController: picker)
        nav.modalPresentationStyle = .formSheet
        ThemeManager.apply(to: nav, traitCollection: nav.traitCollection)
        present(nav, animated: true)
    }

    // MARK: — ContactSelectionDelegate

    func contactSelection(_ controller: ContactSelectionViewController,
                          didSelect contacts: [EmergencyContact]) {
        controller.dismiss(animated: true)
        guard !contacts.isEmpty else { return }
        
        // First prompt for vessel name
        promptForVesselName(
            title: "Emergency SMS",
            message: "What vessel are you on?",
            allowSkip: true
        ) { vesselName in
            // Then prompt for situation
            let alert = UIAlertController(title: "SITREP",
                                          message: "Quick note (optional):",
                                          preferredStyle: .alert)
            alert.addTextField { tf in tf.placeholder = "e.g. ER fire, will update 30mins" }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Send", style: .default) { _ in
                let typed = alert.textFields?.first?.text ?? ""
                self.sendEmergencyText(to: contacts, withSituation: typed, vesselName: vesselName)
            })
            self.present(alert, animated: true)
        }
    }

    // MARK: — Send SMS

    private func sendEmergencyText(to contacts: [EmergencyContact], withSituation situation: String, vesselName: String) {
        guard MFMessageComposeViewController.canSendText() else {
            showAlert(title: "Cannot Send Message", message: "Your device cannot send SMS.")
            return
        }


        // build body
        var locationStr = "Location: Not Available"
        if let loc = latestLocation {
            let lat = loc.coordinate.latitude
            let lon = loc.coordinate.longitude
            let time = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
            locationStr = String(format: "Location: %.4f° N, %.4f° W at %@", lat, lon, time)
        }
        let situationLine = "Situation: \(situation.isEmpty ? "Not provided" : situation)"

        var bodyLines: [String] = [
                "Pilot: \(pilotName)",
                "Vessel: \(vesselName)",
                "Checklist: \(checklist?.title ?? customChecklist?.title ?? "?")",
                locationStr,
                situationLine
            ]
        // tides
        bodyLines.append("")
        bodyLines.append(lastFetchedTideStationName.map { "\($0) Tides:" } ?? "Predicted Tides:")
        bodyLines.append(contentsOf: lastFetchedTideLines ?? ["No data"])
        // winds
        bodyLines.append("")
        bodyLines.append(lastFetchedWindLocationName.map { "\($0) Winds:" } ?? "Forecast Winds:")
        bodyLines.append(contentsOf: lastFetchedWindLines ?? ["No data"])

        let composer = MFMessageComposeViewController()
        composer.messageComposeDelegate = self
        composer.recipients = contacts.map { $0.phone }
        composer.body = bodyLines.joined(separator: "\n")
        present(composer, animated: true)
    }

    // MARK: — MFMessageComposeViewControllerDelegate

    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            let title: String
            switch result {
            case .sent:     title = "Message Sent"
            case .failed:   title = "Send Failed"
            case .cancelled:title = "Cancelled"
            @unknown default: title = "Done"
            }
            let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
            }
        } // End of main class

        // MARK: — UITableViewDataSource
        extension ChecklistViewController {
        
        
        func numberOfSections(in tableView: UITableView) -> Int {
            return checklist?.sections.count ?? customChecklist?.sections.count ?? 0
        }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            // Only show rows if the section is expanded
            guard expandedSections.contains(section) else {
                return 0  // Section is collapsed, show no rows
            }
            
            // Section is expanded, show all items
            let items = checklist?.sections[section].items
                     ?? customChecklist?.sections[section].items
                     ?? []
            return items.count
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            // 1) Grab the model for this row:
            // 1a) Grab whichever array of items we have (built-in or custom)
            let items = checklist?.sections[indexPath.section].items
                     ?? customChecklist?.sections[indexPath.section].items
                     ?? []

            // 1b) Now pull out the single, definite ChecklistItem
            let item = items[indexPath.row]

            // 2) Dequeue *one* ChecklistCell:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "ChecklistCell",
                for: indexPath
            ) as! ChecklistCell

            // 3) Give it the data with quick notes:
            var itemWithNotes = item
            if checklist != nil {
                // For built-in checklists, load the quick note from UserDefaults
                let quickNoteKey = self.builtInQuickNoteKey(for: indexPath)
                if let savedNote = UserDefaults.standard.string(forKey: quickNoteKey) {
                    itemWithNotes.quickNote = savedNote
                }
            }
            cell.configure(with: itemWithNotes)

            // 4) Hook up the tap closures exactly as before:
            cell.checkboxTapped = { [weak self] in
                self?.toggleItem(at: indexPath)
            }
            cell.noteTapped = { [weak self] in
                self?.editNote(forItem: itemWithNotes, at: indexPath)
            }
            cell.cameraTapped = { [weak self] in
                self?.pendingPhotoIndexPath = indexPath
                self?.presentImagePicker()
            }

            return cell
        }
        }

        // MARK: — UITableViewDelegate
extension ChecklistViewController {
    
    func tableView(_ tableView: UITableView,
                   viewForHeaderInSection section: Int) -> UIView? {
        let button = UIButton(type: .system)
        let title = checklist?.sections[section].title
        ?? customChecklist?.sections[section].title
        ?? ""
        let isExpanded = expandedSections.contains(section)
        let chevron = isExpanded ? "chevron.down" : "chevron.right"
        
        button.setTitle("  \(title)", for: .normal)
        button.setImage(UIImage(systemName: chevron), for: .normal)
        
        let fg = ThemeManager.navBarForegroundColor(for: traitCollection)
        button.tintColor       = fg
        button.setTitleColor(fg, for: .normal)
        button.backgroundColor = ThemeManager.navBarColor(for: traitCollection)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 16, bottom: 5, right: 16)
        button.layer.cornerRadius = 8
        button.tag = section
        button.addTarget(self,
                         action: #selector(toggleSection(_:)),
                         for: .touchUpInside)
        return button
    }
    
    func tableView(_ tableView: UITableView,
                   heightForHeaderInSection section: Int) -> CGFloat {
        44
    }
    
    @objc private func toggleSection(_ sender: UIButton) {
        let sec = sender.tag
        if expandedSections.contains(sec) {
            expandedSections.remove(sec)
        } else {
            expandedSections.insert(sec)
        }
        UIView.performWithoutAnimation {
            tableView.reloadSections(IndexSet(integer: sec), with: .none)
        }
    }
    
    private func toggleItem(at indexPath: IndexPath) {
        let now = DateFormatter.localizedString(from: Date(),
                                                dateStyle: .none,
                                                timeStyle: .short)
        
        if var c = checklist {
            c.sections[indexPath.section].items[indexPath.row].isChecked.toggle()
            c.sections[indexPath.section].items[indexPath.row].timestamp =
            c.sections[indexPath.section].items[indexPath.row].isChecked
            ? now
            : nil
            checklist = c
        }
        else if var c = customChecklist {
            c.sections[indexPath.section].items[indexPath.row].isChecked.toggle()
            c.sections[indexPath.section].items[indexPath.row].timestamp =
            c.sections[indexPath.section].items[indexPath.row].isChecked
            ? now
            : nil
            customChecklist = c
            CustomChecklistManager.shared.update(c)
        }
        
        DispatchQueue.main.async {
            // Only reload the specific row that changed, not the entire table
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
    private func addFilenameToItem(at path: IndexPath, filename: String) {
        if var c = checklist {
            if c.sections[path.section].items[path.row].photoFilenames.count < 4 {
                c.sections[path.section].items[path.row].photoFilenames.append(filename)
                checklist = c
                // Save state for built-in checklists
                saveBuiltInChecklistState()
            }
        } else if var c = customChecklist {
            if c.sections[path.section].items[path.row].photoFilenames.count < 4 {
                c.sections[path.section].items[path.row].photoFilenames.append(filename)
                customChecklist = c  // ← This was missing!
                CustomChecklistManager.shared.update(c)
            }
        }
    }
    
    // MARK: — Add Location to Notes
    
    @objc private func addLocationToNotes() {
        isSearchingForGPS = true
        hasAddedLocationToNotes = false
        locationManager.startUpdatingLocation()
        
        // Set a 30-second timeout for GPS acquisition
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            guard let self = self else { return }
            
            if self.isSearchingForGPS {
                self.locationManager.stopUpdatingLocation()
                self.isSearchingForGPS = false
                self.showAlert(title: "GPS Search Timed Out",
                               message: "Unable to get a GPS fix within 30 seconds. Make sure you're in an area with clear sky view and try again.")
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // Good to go - GPS is available
            break
        case .denied, .restricted:
            showAlert(title: "Location Access Denied",
                      message: "Please enable location access in Settings to use GPS coordinates.")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        
        // For remote marine areas, accept locations within 100m accuracy
        if loc.horizontalAccuracy < 100 && loc.horizontalAccuracy > 0 {
            // Only add to notes if we haven't already done so
            if !hasAddedLocationToNotes {
                latestLocation = loc
                isSearchingForGPS = false
                hasAddedLocationToNotes = true
                
                let lat = loc.coordinate.latitude
                let lon = loc.coordinate.longitude
                let time = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
                let accuracy = String(format: "±%.0fm", loc.horizontalAccuracy)
                let line = String(format: "\nLocation: %.4f° N, %.4f° W (%@) at %@", lat, lon, accuracy, time)
                
                if notesTextView.text == "Notes..." {
                    notesTextView.text = ""
                    notesTextView.textColor = ThemeManager.titleColor(for: traitCollection)
                    notesTextView.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
                }
                notesTextView.text += line
                updateNotesTextViewTheme()
                
                locationManager.stopUpdatingLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        showAlert(title: "Location Error", message: error.localizedDescription)
    }
    
    // MARK: — UIImagePickerController
    
    // In ChecklistViewController.swift
    
    private func presentImagePicker() {
        // Check how many photos can still be added
        guard let indexPath = pendingPhotoIndexPath else { return }
        
        let items = checklist?.sections[indexPath.section].items
        ?? customChecklist?.sections[indexPath.section].items
        ?? []
        let currentPhotoCount = items[indexPath.row].photoFilenames.count
        let remainingSlots = 4 - currentPhotoCount
        
        if remainingSlots <= 0 {
            showAlert(title: "Photo Limit Reached", message: "You may only add up to 4 photos per checklist item.")
            pendingPhotoIndexPath = nil
            return
        }
        
        // Use PHPickerViewController for multiple selection
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = remainingSlots // Allow up to remaining slots
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    
    
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let indexPath = pendingPhotoIndexPath else { return }
        
        if results.isEmpty {
            pendingPhotoIndexPath = nil
            return
        }
        
        // Process each selected image
        let group = DispatchGroup()
        var savedFilenames: [String] = []
        
        for result in results {
            group.enter()
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
                defer { group.leave() }
                
                guard let self = self,
                      let image = object as? UIImage,
                      error == nil else {
                    print("Error loading image: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                // Convert to JPEG and save
                if let jpegData = image.jpegData(compressionQuality: 0.8),
                   let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    
                    let filename = "\(UUID().uuidString).jpg"
                    let fileURL = documentsURL.appendingPathComponent(filename)
                    
                    do {
                        try jpegData.write(to: fileURL)
                        savedFilenames.append(filename)
                        print("Successfully saved photo: \(filename)")
                    } catch {
                        print("Error saving photo: \(error)")
                    }
                }
            }
        }
        
        // When all images are processed, update the UI
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            // Add all saved filenames to the checklist item
            for filename in savedFilenames {
                self.addFilenameToItem(at: indexPath, filename: filename)
            }
            
            // Refresh the specific row
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
            self.pendingPhotoIndexPath = nil
            
            print("Added \(savedFilenames.count) photos to checklist item")
        }
    }
    private func saveBuiltInChecklistState() {
        // Save the state of built-in checklists to UserDefaults
        guard let checklist = self.checklist else { return }
        
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(checklist) {
            UserDefaults.standard.set(data, forKey: "builtin_checklist_\(checklist.title)")
        }
    }
    
    private func loadBuiltInChecklistState() {
        // Load saved state for built-in checklists
        guard let checklist = self.checklist else { return }
        
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: "builtin_checklist_\(checklist.title)"),
           let savedChecklist = try? decoder.decode(ChecklistInfo.self, from: data) {
            self.checklist = savedChecklist
        }
    }
    
    private func deleteAllPhotoFiles() {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        // Get all filenames from current checklist
        var allFilenames: [String] = []
        
        if let c = checklist {
            for section in c.sections {
                for item in section.items {
                    allFilenames.append(contentsOf: item.photoFilenames)
                }
            }
        } else if let c = customChecklist {
            for section in c.sections {
                for item in section.items {
                    allFilenames.append(contentsOf: item.photoFilenames)
                }
            }
        }
        
        // Delete each file
        for filename in allFilenames {
            deletePhotoFile(filename: filename)
        }
    }
    
    private func deletePhotoFile(filename: String) {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let fileURL = documentsURL.appendingPathComponent(filename)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("Deleted photo file: \(filename)")
        } catch {
            print("Error deleting photo file \(filename): \(error)")
        }
    }
    
    
    // MARK: — Recording
    
    @objc private func toggleRecording() {
        isRecording ? finishRecording() : startRecording()
    }
    
    private func startRecording() {
        // Show recording indicator briefly
        let recordingAlert = UIAlertController(
            title: "🔴 Recording Started",
            message: "Voice memo in progress.\n\nTap the mic button again to stop recording.",
            preferredStyle: .alert
        )
        
        recordingAlert.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
            // Alert dismissed, recording continues
        })
        
        present(recordingAlert, animated: true) {
            // Start actual recording after presenting the alert
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playAndRecord, mode: .default)
                try session.setActive(true)
                
                // Create filename with checklist name and timestamp
                let checklistName = (self.checklist?.title ?? self.customChecklist?.title ?? "Checklist")
                    .replacingOccurrences(of: "/", with: "-")
                    .replacingOccurrences(of: " ", with: "_")
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
                let timestamp = dateFormatter.string(from: Date())
                let filename = "\(checklistName)_VoiceMemo_\(timestamp).m4a"
                
                let fileURL = FileManager.default
                    .urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent(filename)
                
                let settings: [String: Any] = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 12000,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
                
                self.audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
                self.audioRecorder?.record()
                self.isRecording = true
                self.recordingStartTime = Date()
                self.micButton.tintColor = .systemRed
                
                // Update title bar with recording timer
                self.recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    guard let start = self.recordingStartTime else { return }
                    let sec = Int(Date().timeIntervalSince(start))
                    self.title = String(format: "Recording… %02d:%02d", sec/60, sec%60)
                }
                
                // Auto-dismiss the alert after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if self.presentedViewController is UIAlertController {
                        self.dismiss(animated: true)
                    }
                }
            } catch {
                recordingAlert.dismiss(animated: true) {
                    self.showAlert(title: "Recording Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func finishRecording() {
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        isRecording = false
        micButton.tintColor = ThemeManager.titleColor(for: traitCollection)
        title = checklist?.title ?? customChecklist?.title ?? "Checklist"
        
        // No need to dismiss alert since it auto-dismisses
        showSaveLocationInfo()
    }
    
    private func showSaveLocationInfo() {
        guard let url = audioRecorder?.url else { return }
        
        // Skip the alert entirely and go straight to sharing
        let picker = UIDocumentPickerViewController(forExporting: [url])
        picker.shouldShowFileExtensions = true
        picker.delegate = self  // Add this to detect when user cancels
        present(picker, animated: true)
    }
    
    
    // MARK: — Alerts
    
    private func showAlert(title: String, message: String?) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(.init(title: "OK", style: .default))
        present(ac, animated: true)
    }
    private func promptForVesselName(title: String,
                                     message: String,
                                     allowSkip: Bool = false,
                                     completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Enter vessel name"
            textField.autocapitalizationType = .words
        }
        
        if allowSkip {
            alert.addAction(UIAlertAction(title: "Not Now", style: .cancel) { _ in
                completion("Unknown Vessel")
            })
        } else {
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        }
        
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
            let vesselName = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespaces) ?? ""
            if vesselName.isEmpty {
                completion("Unknown Vessel")
            } else {
                completion(vesselName)
            }
        })
        
        present(alert, animated: true)
    }
    
    // MARK: — UITextViewDelegate
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Notes..." {
            textView.text = ""
            textView.textColor = ThemeManager.titleColor(for: traitCollection)
        }
        updateNotesTextViewTheme()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        let trimmed = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            textView.text = "Notes..."
            textView.textColor = .secondaryLabel
        }
        updateNotesTextViewTheme()
    }
    
    // ─ MARK: – NOAA Tide Helpers ────────────────────────────────────────────────
    
    private func lookupNearestStation(lat: Double, lon: Double, completion: @escaping ((String, String)?) -> Void) {
        var comps = URLComponents(string: "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations.json")!
        comps.queryItems = [
            URLQueryItem(name: "type",  value: "tidepredictions"),
            URLQueryItem(name: "units", value: "english"),
            URLQueryItem(name: "radius", value: "100"),
            URLQueryItem(name: "lat",    value: "\(lat)"),
            URLQueryItem(name: "lon",    value: "\(lon)")
        ]
        guard let url = comps.url else {
            completion(nil); return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard error == nil, let data = data,
                  let root = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
                  let arr = root["stations"] as? [[String:Any]],
                  !arr.isEmpty
            else {
                completion(nil); return
            }
            struct Station { let id, name: String; let lat, lon: Double }
            var cands: [Station] = []
            for dict in arr {
                if let id = dict["id"] as? String,
                   let name = dict["name"] as? String,
                   let lat = dict["lat"] as? Double,
                   let lon = dict["lng"] as? Double {
                    cands.append(.init(id: id, name: name, lat: lat, lon: lon))
                }
            }
            guard !cands.isEmpty else { completion(nil); return }
            let userLoc = CLLocation(latitude: lat, longitude: lon)
            let best = cands.min { a, b in
                let da = CLLocation(latitude: a.lat, longitude: a.lon).distance(from: userLoc)
                let db = CLLocation(latitude: b.lat, longitude: b.lon).distance(from: userLoc)
                return da < db
            }
            completion(best.map { ($0.id, $0.name) })
        }.resume()
    }
    
    private func fetchTidePredictions(station: String, completion: @escaping ([String]?) -> Void) {
        var comps = URLComponents(string: "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter")!
        comps.queryItems = [
            URLQueryItem(name: "station",   value: station),
            URLQueryItem(name: "product",   value: "predictions"),
            URLQueryItem(name: "datum",     value: "MLLW"),
            URLQueryItem(name: "units",     value: "english"),
            URLQueryItem(name: "time_zone", value: "lst_ldt"),
            URLQueryItem(name: "interval",  value: "hilo"),
            URLQueryItem(name: "format",    value: "json"),
            URLQueryItem(name: "date",      value: "today")
        ]
        guard let url = comps.url else { completion(nil); return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard error == nil, let data = data else {
                completion(nil); return
            }
            struct Prediction: Codable { let t, v, type: String }
            struct Root: Codable { let predictions: [Prediction] }
            if let root = try? JSONDecoder().decode(Root.self, from: data) {
                let lines = root.predictions.map { pred -> String in
                    let parts = pred.t.split(separator: " ")
                    let timeOnly = parts.count == 2 ? String(parts[1]) : pred.t
                    let typeL = pred.type == "H" ? "H" : "L"
                    return "\(timeOnly) \(typeL) \(pred.v)′"
                }
                completion(lines.isEmpty ? nil : lines)
            } else {
                completion(nil)
            }
        }.resume()
    }
    
    private func appendTideToNotes(_ lines: [String]) {
        let header = lastFetchedTideStationName.map { "\n\n\($0) Tides:\n" } ?? "\n\nPredicted Tides:\n"
        if notesTextView.text == "Notes..." {
            notesTextView.text = ""
            notesTextView.textColor = ThemeManager.titleColor(for: traitCollection)
            notesTextView.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        }
        notesTextView.text += header + lines.joined(separator: "\n")
        notesTextView.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
    }
    
    @objc private func fetchAndAppendTide() {
        guard let loc = latestLocation else {
            showAlert(title: "Location Needed", message: "Please tap the 🌐 button to fetch your location first.")
            return
        }
        lookupNearestStation(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude) { result in
            guard let (id, name) = result else {
                DispatchQueue.main.async {
                    self.showAlert(title: "No Tide Station Found", message: "Could not locate a nearby tide station.")
                }
                return
            }
            self.lastFetchedTideStationName = name
            self.fetchTidePredictions(station: id) { lines in
                guard let lines = lines else {
                    DispatchQueue.main.async {
                        self.showAlert(title: "Tide Error", message: "Could not load tide data.")
                    }
                    return
                }
                self.lastFetchedTideLines = lines
                DispatchQueue.main.async {
                    self.appendTideToNotes(lines)
                }
            }
        }
    }
    
    // ─ MARK: – NOAA Weather (Wind-Only) Helpers ─────────────────────────────────
    
    private func lookupForecastURL(lat: Double,
                                   lon: Double,
                                   completion: @escaping ((String, String?)?) -> Void)
    {
        let urlString = "https://api.weather.gov/points/\(lat),\(lon)"
        guard let url = URL(string: urlString) else {
            completion(nil); return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard error == nil, let d = data else {
                completion(nil); return
            }
            struct Props: Codable {
                struct Rel: Codable {
                    struct Loc: Codable {
                        let city: String
                        let state: String
                    }
                    let properties: Loc
                }
                let forecast: String
                let relativeLocation: Rel
            }
            struct Root: Codable {
                let properties: Props
            }
            if let root = try? JSONDecoder().decode(Root.self, from: d) {
                let place = "\(root.properties.relativeLocation.properties.city), \(root.properties.relativeLocation.properties.state)"
                completion((root.properties.forecast, place))
            } else {
                completion(nil)
            }
        }.resume()
    }
    
    private func fetchShortWindForecast(fromForecastURL forecastURL: String,
                                        completion: @escaping ([String]?) -> Void)
    {
        guard let url = URL(string: forecastURL) else {
            completion(nil); return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard error == nil, let d = data else {
                completion(nil); return
            }
            struct Period: Codable {
                let name: String
                let startTime: String
                let windSpeed: String
                let windDirection: String
                let isDaytime: Bool
            }
            struct Props: Codable {
                let periods: [Period]
            }
            struct Root: Codable {
                let properties: Props
            }
            if let root = try? JSONDecoder().decode(Root.self, from: d) {
                let nowISO = ISO8601DateFormatter().string(from: Date())
                let nextTwo = root.properties.periods.filter { $0.startTime > nowISO }.prefix(2)
                func toKts(_ mph: Int) -> Int { Int((Double(mph)*0.868976).rounded()) }
                func conv(_ s: String) -> String {
                    let nums = try? NSRegularExpression(pattern: #"\d+"#)
                        .matches(in: s, range: NSRange(s.startIndex..., in: s))
                        .compactMap { Int((s as NSString).substring(with: $0.range)) }
                    guard let arr = nums, !arr.isEmpty else { return s }
                    if arr.count == 1 { return "\(toKts(arr[0])) kts" }
                    return "\(toKts(arr[0]))–\(toKts(arr[1])) kts"
                }
                let lines = nextTwo.map { "\( $0.name ): \($0.windDirection) \(conv($0.windSpeed))" }
                completion(lines.isEmpty ? nil : Array(lines))
            } else {
                completion(nil)
            }
        }.resume()
    }
    
    private func appendWindToNotes(_ lines: [String]) {
        let header = lastFetchedWindLocationName.map { "\n\n\($0) Winds:\n" } ?? "\n\nForecast Winds:\n"
        if notesTextView.text == "Notes..." {
            notesTextView.text = ""
            notesTextView.textColor = ThemeManager.titleColor(for: traitCollection)
            notesTextView.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        }
        notesTextView.text += header + lines.joined(separator: "\n")
        notesTextView.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
    }
    
    @objc private func fetchAndAppendWind() {
        guard let loc = latestLocation else {
            showAlert(title: "Location Needed", message: "Please tap the 🌐 button to fetch your location first.")
            return
        }
        lookupForecastURL(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude) { result in
            guard let (url, place) = result else {
                DispatchQueue.main.async {
                    self.showAlert(title: "No Forecast Found", message: "Could not retrieve a weather forecast for your location.")
                }
                return
            }
            self.lastFetchedWindLocationName = place
            self.fetchShortWindForecast(fromForecastURL: url) { lines in
                guard let lines = lines else {
                    DispatchQueue.main.async {
                        self.showAlert(title: "Wind Error", message: "Could not load wind data.")
                    }
                    return
                }
                self.lastFetchedWindLines = lines
                DispatchQueue.main.async {
                    self.appendWindToNotes(lines)
                }
            }
        }
    }
    
    // MARK: — Export as PDF
    @objc private func confirmGeneratePDF() {
        let alert = UIAlertController(
            title: nil,
            message: "Generate PDF of current contents? This does not clear the checklist.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel",
                                      style: .cancel,
                                      handler: nil))
        alert.addAction(UIAlertAction(title: "Generate",
                                      style: .default) { _ in
            self.generatePDF()
        })
        present(alert, animated: true)
    }
    
    private func generatePDF() {
        // Check if pilot name is set up
        let pilotName = UserDefaults.standard.string(forKey: "pilotName") ?? ""
        if pilotName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let alert = UIAlertController(
                title: "Add Your Name",
                message: "Add your name in Profile for better PDF headers.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Generate Anyway", style: .cancel) { _ in
                self.promptForVesselAndGeneratePDF()
            })
            
            alert.addAction(UIAlertAction(title: "Add Name", style: .default) { _ in
                // Navigate back to main, then to profile
                self.navigationController?.popToRootViewController(animated: true)
                if let mainVC = self.navigationController?.topViewController as? MainViewController {
                    mainVC.openProfile()
                }
            })
            
            present(alert, animated: true)
            return
        }
        
        // If name is set, prompt for vessel and proceed
        promptForVesselAndGeneratePDF()
    }
    private func promptForVesselAndGeneratePDF() {
        promptForVesselName(
            title: "Generate PDF",
            message: "What vessel are you on?",
            allowSkip: false
        ) { vesselName in
            self.pendingVesselName = vesselName
            self.askAboutCaptainSignature()
        }
    }
    
    private func actuallyGeneratePDF() {
        guard let vesselName = pendingVesselName else { return }
        
        // Build filename
        let dateFmt = DateFormatter(); dateFmt.dateFormat = "M.d.yy"
        let dateStr = dateFmt.string(from: Date())
        let rawTitle = checklist?.title ?? customChecklist?.title ?? "Checklist"
        let safeTitle = rawTitle.replacingOccurrences(of: "/", with: ".")
        let fileName = "ShipPilotChecklist_\(safeTitle)_\(dateStr).pdf"
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        // Constants
        let pageW: CGFloat = 612, pageH: CGFloat = 792, margin: CGFloat = 72
        let fmt = UIGraphicsPDFRendererFormat()
        let bounds = CGRect(x: 0, y: 0, width: pageW, height: pageH)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: fmt)
        
        do {
            try renderer.writePDF(to: tmpURL) { ctx in
                ctx.beginPage()
                var y = margin
                
                // 1) Draw header (icon, title, pilot, vessel, date)
                drawPDFHeaderWithWatermark(yStart: &y, pageW: pageW, pageH: pageH, margin: margin, vesselName: vesselName)
                
                // Create an up-to-date version of the checklist data
                var checklistToDraw: [ChecklistSection] = []
                if let builtIn = self.checklist {
                    // For built-in checklists, we inject the saved Quick Notes from UserDefaults
                    var updatedChecklist = builtIn
                    for (sIndex, section) in updatedChecklist.sections.enumerated() {
                        for (iIndex, _) in section.items.enumerated() {
                            let ip = IndexPath(row: iIndex, section: sIndex)
                            let key = self.builtInQuickNoteKey(for: ip)
                            if let note = UserDefaults.standard.string(forKey: key) {
                                updatedChecklist.sections[sIndex].items[iIndex].quickNote = note
                            }
                        }
                    }
                    checklistToDraw = updatedChecklist.sections
                } else if let custom = self.customChecklist {
                    // Custom checklists already have their notes in the main object
                    checklistToDraw = custom.sections
                }
                
                // 2) Draw Sections & items using our new, up-to-date data
                y = drawPDFSections(
                    checklistToDraw,
                    startY:  y,
                    pageW:   pageW,
                    pageH:   pageH,
                    margin:  margin,
                    context: ctx
                )
                
                // 3) Draw the main "Additional Notes" section (if there are notes)
                let currentNotes = notesTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !currentNotes.isEmpty, currentNotes != "Notes..." {
                    y = drawNotesSection(
                        notes: currentNotes,
                        startY: y,
                        pageW: pageW,
                        pageH: pageH,
                        margin: margin,
                        context: ctx
                    )
                }
                
                // 4) Draw signature section with actual signature images
                drawSignatureSectionFixed(
                    yStart: &y,
                    pageW: pageW,
                    pageH: pageH,
                    margin: margin,
                    context: ctx
                )
            }
            
            // Clean up stored signatures
            pilotSignatureImage = nil
            captainSignatureImage = nil
            pendingVesselName = nil
            
            // Present share sheet
            let ac = UIActivityViewController(activityItems: [tmpURL], applicationActivities: nil)
            
            // iPad-specific fix: Set popover source for iPad compatibility
            if let popover = ac.popoverPresentationController {
                popover.sourceView = self.view
                popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            present(ac, animated: true)
            
        } catch {
            showAlert(title: "PDF Error", message: error.localizedDescription)
        }
    }
    
    // MARK: — PDF Helpers
    
    private func drawWatermark(pageW: CGFloat, pageH: CGFloat) {
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String:Any],
           let prim = icons["CFBundlePrimaryIcon"] as? [String:Any],
           let files = prim["CFBundleIconFiles"] as? [String],
           let iconName = files.last,
           let icon = UIImage(named: iconName)
        {
            // Make the watermark large, e.g., 80% of the page width
            let watermarkSize = pageW * 0.8
            // Center it on the page
            let watermarkX = (pageW - watermarkSize) / 2
            let watermarkY = (pageH - watermarkSize) / 2
            let watermarkRect = CGRect(x: watermarkX, y: watermarkY, width: watermarkSize, height: watermarkSize)
            
            // Draw it with a very low opacity to be subtle
            icon.draw(in: watermarkRect, blendMode: .normal, alpha: 0.05)
        }
    }
    
    private func drawPDFHeaderWithWatermark(yStart: inout CGFloat, pageW: CGFloat, pageH: CGFloat, margin: CGFloat, vesselName: String) {
        // Draw watermark first
        drawWatermark(pageW: pageW, pageH: pageH)
        
        let pilot = UserDefaults.standard.string(forKey: "pilotName") ?? "Unknown Pilot"
        let vessel = vesselName
        let date = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
        let title = checklist?.title ?? customChecklist?.title ?? "?"
        let headerLines = [title, "Pilot: \(pilot)", "Vessel: \(vessel)", "Date: \(date)"]
        let fonts = [UIFont.boldSystemFont(ofSize:18)] + Array(repeating: UIFont.systemFont(ofSize:14), count:3)
        
        yStart = margin
        for (i,line) in headerLines.enumerated() {
            let attrs: [NSAttributedString.Key:Any] = [.font: fonts[i], .foregroundColor: ThemeManager.themeColor]
            let rect = CGRect(x: margin, y: yStart, width: pageW-2*margin, height: .greatestFiniteMagnitude)
            let sz = line.boundingRect(with: rect.size,
                                       options: [.usesLineFragmentOrigin],
                                       attributes: attrs, context: nil)
            line.draw(with: rect, options: [.usesLineFragmentOrigin], attributes: attrs, context: nil)
            yStart += sz.height + 4
        }
        yStart += 8
    }
    
    private func drawPDFSections(
        _ sections: [ChecklistSection],
        startY: CGFloat,
        pageW: CGFloat,
        pageH: CGFloat,
        margin: CGFloat,
        context: UIGraphicsPDFRendererContext
    ) -> CGFloat {
        var y = startY
        let bullet = "• "
        let maxW = pageW - 2*margin
        let textFont = UIFont.systemFont(ofSize:14)
        let themeColor = ThemeManager.themeColor
        
        for sec in sections where !sec.items.isEmpty {
            // Section heading
            let secAttrs: [NSAttributedString.Key:Any] = [.font: UIFont.boldSystemFont(ofSize:16), .foregroundColor: themeColor]
            let secRect = CGRect(x: margin, y: y, width: maxW, height: .greatestFiniteMagnitude)
            let secSz = sec.title.boundingRect(with: secRect.size,
                                               options: [.usesLineFragmentOrigin],
                                               attributes: secAttrs, context: nil)
            sec.title.draw(with: secRect, options: [.usesLineFragmentOrigin], attributes: secAttrs, context: nil)
            y += secSz.height + 6
            
            for item in sec.items {
                // Checkbox and Title
                let checkbox = item.isChecked ? "☑" : "☐"
                let titleText = "\(checkbox) \(item.title)"
                let titleAttrs: [NSAttributedString.Key:Any] = [.font: textFont, .foregroundColor: themeColor]
                let titleRect = CGRect(x: margin+10, y: y, width: maxW-10, height: .greatestFiniteMagnitude)
                let titleSz = titleText.boundingRect(with: titleRect.size,
                                                     options: [.usesLineFragmentOrigin],
                                                     attributes: titleAttrs, context: nil)
                titleText.draw(with: titleRect, options: [.usesLineFragmentOrigin], attributes: titleAttrs, context: nil)
                y += titleSz.height + 2
                
                // Timestamp
                if let ts = item.timestamp, !ts.isEmpty {
                    let tsAttrs: [NSAttributedString.Key:Any] = [.font: UIFont.italicSystemFont(ofSize:12), .foregroundColor: themeColor]
                    let tsRect = CGRect(x: margin+20, y: y, width: maxW-20, height: .greatestFiniteMagnitude)
                    let tsSz = ts.boundingRect(with: tsRect.size,
                                               options: [.usesLineFragmentOrigin],
                                               attributes: tsAttrs, context: nil)
                    ts.draw(with: tsRect, options: [.usesLineFragmentOrigin], attributes: tsAttrs, context: nil)
                    y += tsSz.height + 2
                }
                
                // Quick Note
                if let note = item.quickNote?.trimmingCharacters(in: .whitespaces), !note.isEmpty {
                    let noteAttrs: [NSAttributedString.Key:Any] = [
                        .font: UIFont.italicSystemFont(ofSize: 12),
                        .foregroundColor: themeColor
                    ]
                    let noteRect = CGRect(x: margin + 20, y: y, width: maxW - 20, height: .greatestFiniteMagnitude)
                    let noteSz = note.boundingRect(
                        with: noteRect.size,
                        options: [.usesLineFragmentOrigin],
                        attributes: noteAttrs,
                        context: nil
                    )
                    note.draw(with: noteRect, options: [.usesLineFragmentOrigin], attributes: noteAttrs, context: nil)
                    y += noteSz.height + 6
                }
                
                // Photos - Show up to 4 in a row
                let thumb: CGFloat = 40
                let photoSpacing: CGFloat = 6
                let photosToShow = min(item.photoFilenames.count, 4)
                
                if photosToShow > 0 {
                    for (i, fn) in item.photoFilenames.prefix(4).enumerated() {
                        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
                           let img = UIImage(contentsOfFile: docs.appendingPathComponent(fn).path) {
                            let x = margin + 20 + CGFloat(i) * (thumb + photoSpacing)
                            img.draw(in: CGRect(x: x, y: y, width: thumb, height: thumb))
                        }
                    }
                    y += thumb + 8
                }
                
                // Page break
                if y > pageH - margin - 100 {
                    context.beginPage()
                    drawWatermark(pageW: pageW, pageH: pageH)
                    y = margin
                }
            }
        }
        return y
    }
    private func drawNotesSection(
        notes: String,
        startY: CGFloat,
        pageW: CGFloat,
        pageH: CGFloat,
        margin: CGFloat,
        context: UIGraphicsPDFRendererContext
    ) -> CGFloat {
        var y = startY
        let signatureSpace: CGFloat = captainSignatureImage != nil ? 160 : 120
        
        // Add some space before notes
        y += 20
        
        // Check if we need a new page for the notes header
        if y > pageH - margin - signatureSpace - 100 {
            context.beginPage()
            drawWatermark(pageW: pageW, pageH: pageH)
            y = margin
        }
        
        // Header
        let header = "Additional Notes:"
        let headerAttrs: [NSAttributedString.Key:Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: ThemeManager.themeColor
        ]
        let headerSize = header.boundingRect(
            with: CGSize(width: pageW-2*margin, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin],
            attributes: headerAttrs,
            context: nil
        )
        header.draw(
            at: CGPoint(x: margin, y: y),
            withAttributes: headerAttrs
        )
        y += headerSize.height + 8
        
        // Calculate available space for notes on current page
        let availableHeight = pageH - y - margin - signatureSpace
        
        // Notes (in italics)
        let noteAttrs: [NSAttributedString.Key:Any] = [
            .font: UIFont.italicSystemFont(ofSize: 14),
            .foregroundColor: ThemeManager.themeColor
        ]
        
        // Calculate how much space the notes will take
        let noteSize = notes.boundingRect(
            with: CGSize(width: pageW-2*margin, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin],
            attributes: noteAttrs,
            context: nil
        )
        
        // If notes fit on current page with signatures, draw them here
        if noteSize.height <= availableHeight {
            let noteRect = CGRect(x: margin, y: y, width: pageW-2*margin, height: availableHeight)
            notes.draw(
                with: noteRect,
                options: [.usesLineFragmentOrigin],
                attributes: noteAttrs,
                context: nil
            )
            y += noteSize.height + 20
        } else {
            // Notes don't fit, draw as much as possible on current page, continue on next
            let noteRect = CGRect(x: margin, y: y, width: pageW-2*margin, height: availableHeight)
            notes.draw(
                with: noteRect,
                options: [.usesLineFragmentOrigin],
                attributes: noteAttrs,
                context: nil
            )
            // Force signatures to next page
            y = pageH - margin
        }
        
        return y
    }
    
    private func getSavedNotes() -> String? {
        guard let txt = UserDefaults.standard.string(forKey: notesKey), txt != "Notes..." else { return nil }
        return txt
    }
    
    // Clear checklist
    @objc private func promptClearChecklist() {
        let alert = UIAlertController(
            title: "Clear Checklist",
            message: "This will remove ALL checks, notes, and photos from this checklist. This action cannot be undone. Are you sure?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            // Only call the actual clear function if the user confirms
            self.clearChecklist()
        })
        
        present(alert, animated: true)
    }
    
    private func clearChecklist() {
        // 1) Delete all photo files first
        deleteAllPhotoFiles()
        
        // 2) Clear checklist data
        if var c = checklist {
            for s in c.sections.indices {
                for i in c.sections[s].items.indices {
                    // Clear the item's state
                    c.sections[s].items[i].isChecked = false
                    c.sections[s].items[i].timestamp = nil
                    c.sections[s].items[i].photoFilenames.removeAll()
                    let quickNoteKey = self.builtInQuickNoteKey(for: IndexPath(row: i, section: s))
                    UserDefaults.standard.removeObject(forKey: quickNoteKey)
                }
            }
            checklist = c
            
            // Clear saved state
            UserDefaults.standard.removeObject(forKey: "builtin_checklist_\(c.title)")
        }
        else if var c = customChecklist {
            // Delete photos for custom checklist
            for section in c.sections {
                for item in section.items {
                    for filename in item.photoFilenames {
                        deletePhotoFile(filename: filename)
                    }
                }
            }
            
            for s in c.sections.indices {
                for i in c.sections[s].items.indices {
                    c.sections[s].items[i].isChecked = false
                    c.sections[s].items[i].timestamp = nil
                    c.sections[s].items[i].quickNote = nil
                    c.sections[s].items[i].photoFilenames.removeAll()
                }
            }
            customChecklist = c
            CustomChecklistManager.shared.update(c)
        }
        
        // 3) Clear Notes field
        notesTextView.text = "Notes..."
        notesTextView.textColor = .secondaryLabel
        UserDefaults.standard.removeObject(forKey: notesKey)
        
        // 4) Reload table
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    // MARK: — Quick-Note Editing Helper
    
    private func editNote(forItem item: ChecklistItem, at indexPath: IndexPath) {
        // Get the current saved note
        var currentNote: String? = nil
        
        if checklist != nil {
            // For built-in checklists, get from UserDefaults
            let key = self.builtInQuickNoteKey(for: indexPath)
            currentNote = UserDefaults.standard.string(forKey: key)
        } else if let custom = customChecklist {
            // For custom checklists, get from the item
            currentNote = custom.sections[indexPath.section].items[indexPath.row].quickNote
        }
        
        let editor = NoteEditorViewController(initial: currentNote) { newNote in
            // 1) Persist the quick note:
            if self.checklist != nil {
                let key = self.builtInQuickNoteKey(for: indexPath)
                if let txt = newNote {
                    UserDefaults.standard.setValue(txt, forKey: key)
                } else {
                    UserDefaults.standard.removeObject(forKey: key)
                }
            }
            if var custom = self.customChecklist {
                custom.sections[indexPath.section].items[indexPath.row].quickNote = newNote
                self.customChecklist = custom
                CustomChecklistManager.shared.update(custom)
            }
            
            // 2) Refresh that row
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        
        let nav = UINavigationController(rootViewController: editor)
        nav.overrideUserInterfaceStyle = UserDefaults.standard.bool(forKey: "nightMode") ? .dark : .light
        ThemeManager.apply(to: nav, traitCollection: nav.traitCollection)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }
    private func askAboutCaptainSignature() {
        let alert = UIAlertController(
            title: "Signatures Required",
            message: "Does this checklist require a vessel captain's signature?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "No, Just Pilot", style: .default) { _ in
            self.needsCaptainSignature = false
            self.collectPilotSignature()
        })
        
        alert.addAction(UIAlertAction(title: "Yes, Captain Too", style: .default) { _ in
            self.needsCaptainSignature = true
            self.promptForCaptainName()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func promptForCaptainName() {
        let alert = UIAlertController(
            title: "Captain Information",
            message: "Please enter the captain's name:",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Captain's Name"
            textField.autocapitalizationType = .words
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
            let captainName = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespaces) ?? "Captain"
            self.captainName = captainName.isEmpty ? "Captain" : captainName
            self.collectPilotSignature()
        })
        
        present(alert, animated: true)
    }
    
    private func collectPilotSignature() {
        let signatureVC = SignatureViewController()
        signatureVC.signatureFor = "Pilot"
        signatureVC.onSignatureComplete = { [weak self] signatureImage in
            guard let self = self else { return }
            
            signatureVC.dismiss(animated: true) {
                if let image = signatureImage {
                    self.pilotSignatureImage = image
                    
                    if self.needsCaptainSignature {
                        self.collectCaptainSignature()
                    } else {
                        self.actuallyGeneratePDF()
                    }
                }
                // If image is nil, user cancelled - do nothing
            }
        }
        
        let nav = UINavigationController(rootViewController: signatureVC)
        nav.modalPresentationStyle = .overFullScreen
        
        // iPad-specific fix: Set popover source for iPad compatibility
        if let popover = nav.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Apply your app's theme to make buttons visible!
        ThemeManager.apply(to: nav, traitCollection: nav.traitCollection)
        
        present(nav, animated: true)
    }
    
    private func collectCaptainSignature() {
        let signatureVC = SignatureViewController()
        signatureVC.signatureFor = "Captain"
        signatureVC.onSignatureComplete = { [weak self] signatureImage in
            guard let self = self else { return }
            
            signatureVC.dismiss(animated: true) {
                if let image = signatureImage {
                    self.captainSignatureImage = image
                    self.actuallyGeneratePDF()
                }
                // If image is nil, user cancelled - do nothing
            }
        }
        
        let nav = UINavigationController(rootViewController: signatureVC)
        nav.modalPresentationStyle = .overFullScreen
        
        // iPad-specific fix: Set popover source for iPad compatibility
        if let popover = nav.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Apply your app's theme to make buttons visible!
        ThemeManager.apply(to: nav, traitCollection: nav.traitCollection)
        
        present(nav, animated: true)
    }
    
    private func drawSignatureSectionFixed(
        yStart: inout CGFloat,
        pageW: CGFloat,
        pageH: CGFloat,
        margin: CGFloat,
        context: UIGraphicsPDFRendererContext
    ) {
        let signatureHeight: CGFloat = captainSignatureImage != nil ? 160 : 120
        
        // Check if we need a new page for signatures
        if yStart > pageH - margin - signatureHeight {
            context.beginPage()
            drawWatermark(pageW: pageW, pageH: pageH)
            yStart = margin
        }
        
        // Position signatures at bottom of current page, but not too close to current content
        let minSpaceFromContent: CGFloat = 40
        let bottomY = pageH - margin - signatureHeight
        yStart = max(yStart + minSpaceFromContent, bottomY)
        
        let themeColor = ThemeManager.themeColor
        let boldFont = UIFont.boldSystemFont(ofSize: 14)
        let regularFont = UIFont.systemFont(ofSize: 12)
        
        // Draw separator line
        let separatorY = yStart
        let graphicsContext = UIGraphicsGetCurrentContext()
        graphicsContext?.setStrokeColor(themeColor.cgColor)
        graphicsContext?.setLineWidth(1.0)
        graphicsContext?.move(to: CGPoint(x: margin, y: separatorY))
        graphicsContext?.addLine(to: CGPoint(x: pageW - margin, y: separatorY))
        graphicsContext?.strokePath()
        
        yStart += 15
        
        // Signatures header
        let sigHeader = "SIGNATURES"
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 15),
            .foregroundColor: themeColor
        ]
        sigHeader.draw(at: CGPoint(x: margin, y: yStart), withAttributes: headerAttrs)
        yStart += 25
        
        // Current date and time
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let signatureDateTime = dateFormatter.string(from: Date())
        
        // Pilot signature
        let pilotName = UserDefaults.standard.string(forKey: "pilotName") ?? "Pilot"
        "Pilot: \(pilotName)".draw(
            at: CGPoint(x: margin, y: yStart),
            withAttributes: [.font: boldFont, .foregroundColor: themeColor]
        )
        
        "Signed: \(signatureDateTime)".draw(
            at: CGPoint(x: pageW - margin - 150, y: yStart),
            withAttributes: [.font: regularFont, .foregroundColor: themeColor]
        )
        
        yStart += 20
        
        // Draw pilot signature image
        if let pilotSig = pilotSignatureImage {
            let sigRect = CGRect(x: margin, y: yStart, width: 200, height: 50)
            pilotSig.draw(in: sigRect)
        }
        
        yStart += 60
        
        // Captain signature (if provided)
        if let captainSig = captainSignatureImage {
            let displayName = captainName ?? "Captain"
            "Captain: \(displayName)".draw(
                at: CGPoint(x: margin, y: yStart),
                withAttributes: [.font: boldFont, .foregroundColor: themeColor]
            )
            
            "Signed: \(signatureDateTime)".draw(
                at: CGPoint(x: pageW - margin - 150, y: yStart),
                withAttributes: [.font: regularFont, .foregroundColor: themeColor]
            )
            
            yStart += 20
            
            // Draw captain signature image
            let captainSigRect = CGRect(x: margin, y: yStart, width: 200, height: 50)
            captainSig.draw(in: captainSigRect)
        }
    }
}
        // MARK: - UIDocumentPickerDelegate
extension ChecklistViewController {
            func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
                // User successfully exported the file
                showAlert(title: "Success", message: "Voice memo saved.")
            }
            
            func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
                // User cancelled - the recording is lost since we can't access it in-app
                showAlert(title: "Recording Not Saved", message: "The voice memo was not exported and cannot be recovered.")
            }
            
        }
    

