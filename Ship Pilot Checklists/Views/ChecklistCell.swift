//checklistcell.swift

import UIKit

class ChecklistCell: UITableViewCell {
    // MARK: - UI Subviews
    let checkbox = UIButton(type: .system)
    let titleLabel = UILabel()
    let pencilButton = UIButton(type: .system)
    let cameraButton = UIButton(type: .system)

    // Details container
    private let detailsContainer = UIView()
    private let timestampLabel = UILabel()
    private let noteLabel = UILabel()
    private let photosContainer = UIView()

    // MARK: - Closures
    var checkboxTapped: (() -> Void)?
    var noteTapped: (() -> Void)?
    var cameraTapped: (() -> Void)?
    var photoTapped: ((Int) -> Void)?
    
    // MARK: - Private properties
    private var detailsContainerHeightConstraint: NSLayoutConstraint!
    private var currentPhotoViews: [UIImageView] = []
    private var currentPhotoFilenames: [String] = [] // NEW: Store filenames for tap handling
    private var photosContainerHeightConstraint: NSLayoutConstraint! // NEW: Dynamic height constraint

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Setup
    private func setupViews() {
        // Configure title label
        titleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        // Configure buttons
        setupButtons()
        
        // Configure detail views
        setupDetailViews()
        
        // Add main subviews to content view
        [checkbox, titleLabel, pencilButton, cameraButton, detailsContainer].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // Add detail subviews to details container
        [timestampLabel, noteLabel, photosContainer].forEach {
            detailsContainer.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        // Setup constraints
        setupConstraints()
        
        // Prevent cell selection from interfering with photo taps
            selectionStyle = .none
    }
    
    private func setupButtons() {
        // Checkbox setup
        checkbox.setContentHuggingPriority(.required, for: .horizontal)
        checkbox.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        // Pencil button setup
        let pencilCfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        pencilButton.setImage(UIImage(systemName: "pencil", withConfiguration: pencilCfg), for: .normal)
        pencilButton.addTarget(self, action: #selector(didTapPencil), for: .touchUpInside)
        pencilButton.setContentHuggingPriority(.required, for: .horizontal)
        pencilButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        // Camera button setup
        let photoCfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        cameraButton.setImage(UIImage(systemName: "photo", withConfiguration: photoCfg), for: .normal)
        cameraButton.addTarget(self, action: #selector(didTapCamera), for: .touchUpInside)
        cameraButton.setContentHuggingPriority(.required, for: .horizontal)
        cameraButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        checkbox.addTarget(self, action: #selector(didTapCheckbox), for: .touchUpInside)
    }
    
    private func setupDetailViews() {
        // Details container
        detailsContainer.backgroundColor = .clear
        
        // Timestamp label
        timestampLabel.font = .systemFont(ofSize: 12)
        timestampLabel.textColor = .secondaryLabel
        timestampLabel.numberOfLines = 1
        
        // Note label
        noteLabel.font = .italicSystemFont(ofSize: 14)
        noteLabel.numberOfLines = 0
        noteLabel.textColor = .label
        
        // Photos container
        photosContainer.backgroundColor = .clear
    }
    
    private func setupConstraints() {
        // Create height constraint for details container
        detailsContainerHeightConstraint = detailsContainer.heightAnchor.constraint(equalToConstant: 0)
        detailsContainerHeightConstraint.priority = .defaultHigh
        
        // Create dynamic height constraint for photos container
        photosContainerHeightConstraint = photosContainer.heightAnchor.constraint(equalToConstant: 0)
        
        NSLayoutConstraint.activate([
            // Checkbox - fixed position
            checkbox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            checkbox.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            checkbox.widthAnchor.constraint(equalToConstant: 28),
            checkbox.heightAnchor.constraint(equalToConstant: 28),

            // Camera button - fixed position (rightmost)
            cameraButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            cameraButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            cameraButton.widthAnchor.constraint(equalToConstant: 30),
            cameraButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Pencil button - fixed position (to left of camera)
            pencilButton.trailingAnchor.constraint(equalTo: cameraButton.leadingAnchor, constant: -12),
            pencilButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            pencilButton.widthAnchor.constraint(equalToConstant: 30),
            pencilButton.heightAnchor.constraint(equalToConstant: 30),

            // Title - fills remaining space
            titleLabel.leadingAnchor.constraint(equalTo: checkbox.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: pencilButton.leadingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),

            // Details container
            detailsContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            detailsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 58),
            detailsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            detailsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            detailsContainerHeightConstraint,
            
            // Timestamp label inside details container
            timestampLabel.topAnchor.constraint(equalTo: detailsContainer.topAnchor),
            timestampLabel.leadingAnchor.constraint(equalTo: detailsContainer.leadingAnchor),
            timestampLabel.trailingAnchor.constraint(equalTo: detailsContainer.trailingAnchor),
            
            // Note label below timestamp
            noteLabel.topAnchor.constraint(equalTo: timestampLabel.bottomAnchor, constant: 4),
            noteLabel.leadingAnchor.constraint(equalTo: detailsContainer.leadingAnchor),
            noteLabel.trailingAnchor.constraint(equalTo: detailsContainer.trailingAnchor),
            
            // Photos container below note
            photosContainer.topAnchor.constraint(equalTo: noteLabel.bottomAnchor, constant: 4),
            photosContainer.leadingAnchor.constraint(equalTo: detailsContainer.leadingAnchor),
            photosContainer.trailingAnchor.constraint(equalTo: detailsContainer.trailingAnchor),
            photosContainer.bottomAnchor.constraint(lessThanOrEqualTo: detailsContainer.bottomAnchor),
            photosContainerHeightConstraint // Use the dynamic constraint
        ])
    }

    // MARK: - Configuration
    func configure(with item: ChecklistItem) {
        // CRITICAL: Always set title first and ensure it's visible
        titleLabel.text = item.title
        titleLabel.isHidden = false
        
        // Configure checkbox
        checkbox.setImage(UIImage(systemName: item.isChecked ? "checkmark.square" : "square"), for: .normal)
        
        // Configure colors
        let active = ThemeManager.titleColor(for: traitCollection)
        let disabled = UIColor.systemGray
        checkbox.tintColor = active
        titleLabel.textColor = active
        pencilButton.tintColor = active
        
        // Camera button state
        cameraButton.tintColor = item.photoFilenames.count < 4 ? active : disabled
        cameraButton.isEnabled = item.photoFilenames.count < 4

        // Configure details
        configureDetails(item: item)
    }
    
    private func configureDetails(item: ChecklistItem) {
        let hasTimestamp = !(item.timestamp ?? "").isEmpty
        let hasNote = !(item.quickNote ?? "").isEmpty
        let hasPhotos = !item.photoFilenames.isEmpty
        
        // Configure timestamp
        if hasTimestamp {
            timestampLabel.text = item.timestamp
            timestampLabel.isHidden = false
        } else {
            timestampLabel.text = ""
            timestampLabel.isHidden = true
        }
        
        // Configure note
        if hasNote {
            noteLabel.text = item.quickNote
            noteLabel.isHidden = false
        } else {
            noteLabel.text = ""
            noteLabel.isHidden = true
        }
        
        // Configure photos
        configurePhotos(item.photoFilenames)
        
        // Calculate and set details container height
        let detailsHeight = calculateDetailsHeight(hasTimestamp: hasTimestamp, hasNote: hasNote, hasPhotos: hasPhotos, item: item)
        detailsContainerHeightConstraint.constant = detailsHeight
        detailsContainer.isHidden = detailsHeight == 0
        
        // Force layout update
        layoutIfNeeded()
    }
    
    private func calculateDetailsHeight(hasTimestamp: Bool, hasNote: Bool, hasPhotos: Bool, item: ChecklistItem) -> CGFloat {
        var height: CGFloat = 0
        
        if hasTimestamp {
            height += 16 // Approximate height for timestamp
        }
        
        if hasNote {
            if hasTimestamp { height += 4 } // Spacing
            
            // Calculate actual height needed for the note text
            let noteText = item.quickNote ?? ""
            let maxWidth = UIScreen.main.bounds.width - 73 // Account for margins and indentation
            let noteSize = noteText.boundingRect(
                with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin],
                attributes: [.font: UIFont.italicSystemFont(ofSize: 14)],
                context: nil
            )
            height += noteSize.height + 8 // Add some padding
        }
        
        if hasPhotos {
            if hasTimestamp || hasNote { height += 4 } // Spacing
            height += 58 // Single row height (50pt photo + 8pt padding)
        }
        
        return height
    }
    
    private func configurePhotos(_ filenames: [String]) {
        // Remove existing photo views
        currentPhotoViews.forEach { $0.removeFromSuperview() }
        currentPhotoViews.removeAll()
        
        // NEW: Store filenames for tap handling
        currentPhotoFilenames = filenames
        
        if filenames.isEmpty {
            photosContainer.isHidden = true
            // Set height to 0 when no photos
            photosContainerHeightConstraint.constant = 0
            return
        }
        
        photosContainer.isHidden = false
        // Set height to 50 when photos are present
        photosContainerHeightConstraint.constant = 50
        
        // IMPORTANT: Ensure photos container can receive touches
        photosContainer.isUserInteractionEnabled = true
        
        // DEBUG: Check the photosContainer frame
        print("📦 photosContainer frame: \(photosContainer.frame)")
        print("📦 photosContainer bounds: \(photosContainer.bounds)")
        
        // Add up to 4 photos
        for (index, filename) in filenames.prefix(4).enumerated() {
            let imageView = createPhotoImageView()
            loadImage(into: imageView, filename: filename)
            
            photosContainer.addSubview(imageView)
            currentPhotoViews.append(imageView)
            
            // Position photos in a single row (4 across) using FRAME instead of constraints
            let xOffset = CGFloat(index) * 58 // 50 width + 8 spacing
            imageView.frame = CGRect(x: xOffset, y: 0, width: 50, height: 50)
            
            // CRITICAL: Set this AFTER adding to superview and setting frame
            imageView.isUserInteractionEnabled = true
            
            // Add tap gesture for enlarging
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(photoTapped(_:)))
            tapGesture.numberOfTapsRequired = 1
            tapGesture.numberOfTouchesRequired = 1
            imageView.addGestureRecognizer(tapGesture)
            imageView.tag = index // Store index for later reference
            
            // DEBUG: Test if tap gesture can be triggered manually
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("🧪 Testing tap gesture for photo \(index)")
                print("🧪 ImageView frame: \(imageView.frame)")
                print("🧪 ImageView superview: \(imageView.superview?.description ?? "nil")")
                print("🧪 ImageView isUserInteractionEnabled: \(imageView.isUserInteractionEnabled)")
                print("🧪 ImageView gestureRecognizers count: \(imageView.gestureRecognizers?.count ?? 0)")
                
                // Try to manually trigger the gesture
                if let gestureRecognizers = imageView.gestureRecognizers {
                    for gesture in gestureRecognizers {
                        print("🧪 Gesture: \(gesture)")
                        if let tapGesture = gesture as? UITapGestureRecognizer {
                            print("🧪 Found tap gesture, state: \(tapGesture.state.rawValue)")
                        }
                    }
                }
            }
            
            // Debug: Print when tap gesture is added
            print("➕ Added tap gesture to photo \(index) for filename: \(filename), frame: \(imageView.frame)")
        }
        
        // Force layout to make sure frames are set
        photosContainer.layoutIfNeeded()
        
        // DEBUG: Print final photosContainer info
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            print("📦 FINAL photosContainer frame: \(self.photosContainer.frame)")
            print("📦 FINAL photosContainer subviews count: \(self.photosContainer.subviews.count)")
        }
    }
    
    private func createPhotoImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 6
        imageView.layer.borderWidth = 0.5
        imageView.layer.borderColor = UIColor.systemGray4.cgColor
        imageView.backgroundColor = UIColor.systemGray6
        // REMOVE this line that was causing layout conflicts:
        // imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }
    
    private func loadImage(into imageView: UIImageView, filename: String) {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let fileURL = documentsURL.appendingPathComponent(filename)
        
        // Load image synchronously for stability
        if let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            imageView.image = image
        }
    }

    // MARK: - Actions
    @objc private func didTapCheckbox() {
        checkboxTapped?()
    }
    
    @objc private func didTapPencil() {
        noteTapped?()
    }
    
    @objc private func didTapCamera() {
        cameraTapped?()
    }
    
    @objc private func photoTapped(_ gesture: UITapGestureRecognizer) {
        guard let imageView = gesture.view as? UIImageView else { return }
        let photoIndex = imageView.tag
        photoTapped?(photoIndex)
    }
    
    // MARK: - Cell Lifecycle
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Clear photos
        currentPhotoViews.forEach { $0.removeFromSuperview() }
        currentPhotoViews.removeAll()
        currentPhotoFilenames.removeAll() // NEW: Clear stored filenames
        
        // Reset all content
        titleLabel.text = ""
        titleLabel.isHidden = false
        timestampLabel.text = ""
        timestampLabel.isHidden = true
        noteLabel.text = ""
        noteLabel.isHidden = true
        photosContainer.isHidden = true
        
        // Reset details container
        detailsContainerHeightConstraint.constant = 0
        detailsContainer.isHidden = true
        
        // Reset button states
        cameraButton.isEnabled = true
        cameraButton.tintColor = ThemeManager.titleColor(for: traitCollection)
    }
}
