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
        
        // Emergency Features
        addTitle("QUICK START - ANY CHECKLIST")
        addBullet("text.bubble", text: "Emergency SMS: Tap message icon → select contacts → enter vessel → send")
        addBullet("globe", text: "GPS Location: Tap globe to add coordinates to notes")
        addBullet("water.waves", text: "Tide Data: Add location first, then tap tide icon")
        addBullet("wind", text: "Wind Data: Add location first, then tap wind icon")
        addBullet("doc.text", text: "PDF Report: Tap document icon → enter vessel → sign")
        
        // Using Checklists
        addTitle("USING CHECKLISTS")
        addBullet("checkmark.square", text: "Tap checkbox to mark complete (auto-timestamps)")
        addBullet("pencil", text: "Add notes to any item")
        addBullet("photo", text: "Add photos (max 4 per item)")
        addBullet("mic", text: "Record voice memos")
        addBullet("eraser", text: "Clear all data (cannot undo)")
        
        // Navigation
        addTitle("NAVIGATION")
        addBullet("star", text: "Swipe right or press star on any checklist to favorite")
        addBullet("magnifyingglass", text: "Search all checklists from main menu")
        addBullet("sun.max", text: "Toggle day/night mode")
        addBullet("chevron.up.chevron.down", text: "Tap section headers to expand/collapse")
        
        // Setup Requirements
        addTitle("INITIAL SETUP")
        addBullet("person", text: "Add your name in Profile (required for SMS/PDF)")
        addBullet("phone", text: "Add emergency contacts in Contacts")
        addBullet("location", text: "Allow location access for GPS features")
        
        // Custom Checklists
        addTitle("CUSTOM CHECKLISTS")
        addBullet("plus", text: "Create: Tap 'Create New Checklist' to make a blank checklist")
        addBullet("square.and.arrow.down", text: "Import Checklist: Tap 'Import Checklist from .csv' to import from Excel")
        addBullet("info.circle", text: "The file must use 2 headers: Priority, Item")
        addBullet("info.circle", text: "Each row defines one item under a category (like High, Medium, Low). You may name the categories however you like (Critical, Post Incident, etc.).")
        addBullet("info.circle", text: "Save Excel file as: 'Comma Separated Values (.csv)', NOT UTF-8 format")
        addBullet("square.and.arrow.up", text: "Share Custom Checklist: Swipe left → Share → send .shipchecklist file")
        addBullet("pencil.and.list.clipboard", text: "Custom: Tap clipboard icon on any Included Checklist to send to Custom Checklists.")
        addBullet("pencil", text: "Tap pencil icon to edit a custom checklist.")
        addBullet("star", text: "Tap star icon to add checklist to Favorites.")

        
        // Contacts System
        addTitle("CONTACTS")
        addBullet("person.2", text: "Organized by categories (Emergency, Coast Guard, etc.)")
        addBullet("phone", text: "Tap to call, swipe for more options")
        addBullet("plus.circle", text: "Import from phone contacts or add manually")
        
        // Data & Privacy
        addTitle("DATA")
        body.append(NSAttributedString(
            string: "• All data stored locally on device\n• No internet required (except tide/wind)\n• Tide: NOAA\n• Wind: National Weather Service\n\n",
            attributes: [
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraph
            ]
        ))
        
        // Support
        addTitle("SUPPORT")
        body.append(NSAttributedString(
            string: "captjillr+app@gmail.com\n\n",
            attributes: [
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraph
            ]
        ))
        
        helpTextView.attributedText = body
    }
}
