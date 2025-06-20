import UIKit

class HelpViewController: UIViewController {

    private let helpTextView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isEditable = false
        tv.isScrollEnabled = true
        tv.backgroundColor = .clear
        return tv
    }()

    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        let cfg = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        btn.setImage(UIImage(systemName: "xmark.square", withConfiguration: cfg), for: .normal)
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // allow content to extend behind bars
        edgesForExtendedLayout = [.all]
        extendedLayoutIncludesOpaqueBars = true

        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        setupViews()
        applyTheme()
        configureHelpText()

        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        applyTheme()
        configureHelpText()
    }

    private func setupViews() {
        view.addSubview(helpTextView)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),

            helpTextView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 20),
            helpTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            helpTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            helpTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
        ])
    }

    private func applyTheme() {
        let textColor = ThemeManager.titleColor(for: traitCollection)
        helpTextView.textColor = textColor
        closeButton.tintColor = textColor
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    private func configureHelpText() {
        let textColor = ThemeManager.titleColor(for: traitCollection)
        let font = UIFont.systemFont(ofSize: 16)
        let boldFont = UIFont.boldSystemFont(ofSize: 18)
        let largeBoldFont = UIFont.boldSystemFont(ofSize: 20)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4
        
        let body = NSMutableAttributedString()
        
        func addTitle(_ text: String) {
            let attr = NSAttributedString(
                string: "\n\(text)\n\n",
                attributes: [
                    .font: largeBoldFont,
                    .foregroundColor: textColor,
                    .paragraphStyle: paragraph
                ]
            )
            body.append(attr)
        }
        
        func addBullet(_ symbol: String, text: String) {
            let attach = NSTextAttachment()
            let cfg = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            attach.image = UIImage(systemName: symbol, withConfiguration: cfg)?
                .withTintColor(textColor, renderingMode: .alwaysOriginal)
            attach.bounds = CGRect(x: 0, y: -2, width: 18, height: 18)
            body.append(NSAttributedString(attachment: attach))
            let line = NSAttributedString(
                string: "  \(text)\n\n",
                attributes: [
                    .font: font,
                    .foregroundColor: textColor,
                    .paragraphStyle: paragraph
                ]
            )
            body.append(line)
        }
        
        // Emergency section
        addTitle("EMERGENCY QUICK START")
        addBullet("text.bubble", text: "Emergency SMS: Tap message bubble → select contacts → vessel name → send")
        addBullet("globe", text: "Add Location: Tap globe icon to add GPS coordinates to notes")
        addBullet("water.waves.and.arrow.trianglehead.up", text: "Get Tide Data: Tap wave icon after adding location")
        addBullet("wind", text: "Get Wind Data: Tap wind icon after adding location")
        addBullet("doc.text", text: "Generate Report: Tap document icon → vessel name → create PDF")
        
        // Basic use
        addTitle("BASIC CHECKLIST USE")
        addBullet("checkmark.square", text: "Tap items to check them off (timestamps automatically)")
        addBullet("pencil", text: "Tap pencil icon to add notes to any item")
        addBullet("photo", text: "Tap photo icon to add photos (up to 4 per item)")
        addBullet("star", text: "Swipe right to favorite any checklist")
        addBullet("square.and.arrow.up", text: "Swipe left on Custom Checklists to share with other pilots")
        
        // Setup
        addTitle("SETUP & PROFILE")
        addBullet("person.crop.circle", text: "Set your name in Profile (top right)")
        addBullet("phone", text: "Add emergency contacts in Profile")
        addBullet("location", text: "Enable location services for GPS/tide/wind features")
        
        // Custom checklists
        addTitle("CUSTOM CHECKLISTS")
        addBullet("plus", text: "Create new checklists with 'Add New Checklist +'")
        addBullet("pencil.and.list.clipboard", text: "Convert any included checklist to custom (tap clipboard icon)")
        addBullet("square.and.arrow.up", text: "Share custom checklists: swipe left → Share → send .shipchecklist file")
        addBullet("square.and.arrow.down", text: "Import shared checklists: tap received .shipchecklist file")
        
        // Features
        addTitle("FEATURES")
        addBullet("mic", text: "Voice Memos: Tap mic icon to record audio notes")
        addBullet("moon", text: "Night Mode: Toggle sun/moon icon for dark conditions")
        addBullet("star", text: "Favorites: Quick access to most-used checklists")
        addBullet("eraser", text: "Clear Checklist: Eraser icon removes all data (cannot be undone)")
        
        // Data sources
        addTitle("DATA SOURCES")
        body.append(NSAttributedString(
            string: "Tide predictions: NOAA Tides & Currents\nWind forecasts: National Weather Service\nGPS coordinates: Device location services\n\n",
            attributes: [
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraph
            ]
        ))
        
        // Support
        addTitle("SUPPORT")
        body.append(NSAttributedString(
            string: "Contact: captjillr+app@gmail.com\n\n",
            attributes: [
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraph
            ]
        ))
        
        helpTextView.attributedText = body
    }
}
