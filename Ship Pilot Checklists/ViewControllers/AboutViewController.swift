import UIKit

class AboutViewController: UIViewController {

    private let versionLabel = UILabel()
    private let privacyPolicyLabel = UILabel()
    private let developerInfoTextView = UITextView()
    private let closeButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Allow content to extend under nav-bar, then push down via safeArea
        edgesForExtendedLayout = [.all]
        extendedLayoutIncludesOpaqueBars = true

        setupViews()
        applyTheme()
        loadAppInfo()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyTheme()
    }

    // MARK: - Theme
    private func applyTheme() {
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        let textColor = ThemeManager.titleColor(for: traitCollection)

        versionLabel.textColor = textColor
        developerInfoTextView.textColor = textColor
        closeButton.tintColor = textColor
        
        // Update privacy policy link color
        setupPrivacyPolicyLink()
    }

    // MARK: - Setup Views
    private func setupViews() {
        view.addSubview(closeButton)
        view.addSubview(versionLabel)
        view.addSubview(privacyPolicyLabel)
        view.addSubview(developerInfoTextView)

        // Close Button
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        let image = UIImage(systemName: "xmark.square", withConfiguration: config)
        closeButton.setImage(image, for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)

        // Version Label
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.textAlignment = .center
        versionLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)

        // Privacy Policy Label
        privacyPolicyLabel.translatesAutoresizingMaskIntoConstraints = false
        privacyPolicyLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        privacyPolicyLabel.numberOfLines = 0
        privacyPolicyLabel.isUserInteractionEnabled = true
        
        // Add tap gesture to privacy policy
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(privacyPolicyTapped))
        privacyPolicyLabel.addGestureRecognizer(tapGesture)

        // Developer Info TextView
        developerInfoTextView.translatesAutoresizingMaskIntoConstraints = false
        developerInfoTextView.isEditable = false
        developerInfoTextView.font = UIFont.systemFont(ofSize: 16)
        developerInfoTextView.text = """
Ship Pilot Checklists

We do not collect, store, or process any personal data through the Ship Pilot Checklists app. The app is designed to work offline, and no data is sent to any third parties. We ask for permission to access location data, audio and photos ONLY for local display of your lat/long, and to access on-device storage of your audio files or photos that you initiate. Nothing is saved nor tracked by the app.
"""
        developerInfoTextView.textContainer.lineFragmentPadding = 0
        developerInfoTextView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)

        // Layout constraints
        NSLayoutConstraint.activate([
            // Pin close button beneath safeArea
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            versionLabel.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 20),
            versionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            versionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            privacyPolicyLabel.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: 16),
            privacyPolicyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            privacyPolicyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            developerInfoTextView.topAnchor.constraint(equalTo: privacyPolicyLabel.bottomAnchor, constant: 16),
            developerInfoTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            developerInfoTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Pin bottom of textView to safeArea bottom
            developerInfoTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        
        // Setup the clickable privacy policy link
        setupPrivacyPolicyLink()
    }
    
    // MARK: - Setup Privacy Policy Link
    private func setupPrivacyPolicyLink() {
        let fullText = "Privacy Policy: https://tinyurl.com/422try48"
        let attributedString = NSMutableAttributedString(string: fullText)
        
        // Set default color for the whole text
        let textColor = ThemeManager.titleColor(for: traitCollection)
        attributedString.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: fullText.count))
        
        // Find the URL part and make it blue and underlined
        if let urlRange = fullText.range(of: "https://tinyurl.com/y9pb43mw") {
            let nsRange = NSRange(urlRange, in: fullText)
            attributedString.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: nsRange)
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
        }
        
        privacyPolicyLabel.attributedText = attributedString
    }

    // MARK: - Load Info
    private func loadAppInfo() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            versionLabel.text = "Version: \(version) (Build: \(build))"
        } else {
            versionLabel.text = "Version info not available"
        }
    }

    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func privacyPolicyTapped() {
        if let url = URL(string: "https://tinyurl.com/y9pb43mw") {
            UIApplication.shared.open(url)
        }
    }
}
