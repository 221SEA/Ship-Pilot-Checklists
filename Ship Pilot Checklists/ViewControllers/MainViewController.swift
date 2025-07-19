import UIKit

//
//  MainViewController.swift
//  Ship Pilot Checklists
//

class MainViewController: UIViewController {
    
    private var isNightMode = false
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Ship Pilot"
        label.font = UIFont.boldSystemFont(ofSize: 32)
        label.textAlignment = .center
        return label
    }()
    
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "AppWatermark"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.alpha = 0.06
        return imageView
    }()
    
    private lazy var buttonsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            makeNavButton(title: "Included Checklists", icon: "list.clipboard"),
            makeNavButton(title: "Custom Checklists", icon: "pencil.and.list.clipboard"),
            makeNavButton(title: "Favorites", icon: "star"),
            makeNavButton(title: "Contacts", icon: "person.2"),
            makeNavButton(title: "Saved Files", icon: "folder")
        ])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // MARK: – Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = [.all]
        extendedLayoutIncludesOpaqueBars = true
        loadNightModePreference()
        overrideUserInterfaceStyle = isNightMode ? .dark : .light
        setupNavigationBarButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: false)
        navigationController?.navigationBar.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkDisclaimer()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        ThemeManager.apply(to: navigationController, traitCollection: traitCollection)
        setupNavigationBarButtons()
        setupMainView()
    }
    
    // MARK: – Disclaimer & Layout
    
    private func checkDisclaimer() {
        if !UserDefaults.standard.bool(forKey: "disclaimerAgreed") {
            let disclaimerVC = DisclaimerViewController()
            disclaimerVC.modalPresentationStyle = .overFullScreen
            applyUserInterfaceStyle(to: disclaimerVC)
            present(disclaimerVC, animated: false)
        } else {
            setupMainView()
        }
    }
    
    private func setupMainView() {
        view.subviews.forEach { $0.removeFromSuperview() }
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        view.addSubview(backgroundImageView)
        view.addSubview(titleLabel)
        view.addSubview(buttonsStackView)
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            backgroundImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1.5),
            backgroundImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1.5),
            
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            
            buttonsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            buttonsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            buttonsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30)
        ])
        
        titleLabel.textColor = ThemeManager.titleColor(for: traitCollection)
    }
    
    // MARK: – Nav Buttons & Helpers
    
    private func makeNavButton(title: String, icon: String) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = ThemeManager.themeColor
        button.setTitle("  \(title)", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.layer.cornerRadius = 10
        button.contentHorizontalAlignment = .leading
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
        button.tintColor = .white
        
        switch title {
        case "Included Checklists":
            button.addTarget(self, action: #selector(openChecklists), for: .touchUpInside)
        case "Custom Checklists":
            button.addTarget(self, action: #selector(openCustomChecklists), for: .touchUpInside)
        case "Favorites":
            button.addTarget(self, action: #selector(openFavorites), for: .touchUpInside)
        case "Contacts":
            button.addTarget(self, action: #selector(openContacts), for: .touchUpInside)
        case "Saved Files":
            button.addTarget(self, action: #selector(openSavedFiles), for: .touchUpInside)
        default: break
        }
        return button
    }
    
    private func setupNavigationBarButtons() {
        let tint: UIColor = traitCollection.userInterfaceStyle == .dark ? .green : .white
        let infoButton = UIButton(type: .system)
        infoButton.setImage(UIImage(systemName: "info.circle"), for: .normal)
        infoButton.tintColor = tint
        infoButton.addTarget(self, action: #selector(presentAboutViewController), for: .touchUpInside)
        
        let helpButton = UIButton(type: .system)
        helpButton.setImage(UIImage(systemName: "questionmark.circle"), for: .normal)
        helpButton.tintColor = tint
        helpButton.addTarget(self, action: #selector(presentHelpViewController), for: .touchUpInside)
        
        let searchButton = UIButton(type: .system)
        searchButton.setImage(UIImage(systemName: "text.magnifyingglass"), for: .normal)
        searchButton.tintColor = tint
        searchButton.addTarget(self, action: #selector(presentSearchViewController), for: .touchUpInside)
        
        let leftStack = UIStackView(arrangedSubviews: [infoButton, helpButton, searchButton])
        leftStack.axis = .horizontal
        leftStack.spacing = 16
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftStack)
        
        let profile = UIBarButtonItem(
            image: UIImage(systemName: "person.crop.circle"),
            style: .plain,
            target: self,
            action: #selector(openProfile)
        )
        profile.tintColor = tint
        
        let iconName = isNightMode ? "moon" : "sun.max"
        let toggle = UIBarButtonItem(
            image: UIImage(systemName: iconName),
            style: .plain,
            target: self,
            action: #selector(toggleNightMode)
        )
        toggle.tintColor = tint
        
        navigationItem.rightBarButtonItems = [profile, toggle]
    }
    @objc private func openSavedFiles() {
        let vc = SavedFilesViewController()
        applyUserInterfaceStyle(to: vc)
        navigationController?.pushViewController(vc, animated: true)
    }
    @objc private func presentSearchViewController() {
        let searchVC = SearchViewController()
        let nav = UINavigationController(rootViewController: searchVC)
        applyUserInterfaceStyle(to: nav)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    @objc func openProfile() {  // ← This handles the nav bar button tap
        let settingsVC = SettingsViewController()
        settingsVC.cameFromPDFGeneration = true  // Simple profile opening
        let nav = UINavigationController(rootViewController: settingsVC)
        ThemeManager.apply(to: nav, traitCollection: nav.traitCollection)
        present(nav, animated: true)
    }
    
    @objc private func toggleNightMode() {
        isNightMode.toggle()
        UserDefaults.standard.set(isNightMode, forKey: "nightMode")
        overrideUserInterfaceStyle = isNightMode ? .dark : .light
        setupMainView()
        setupNavigationBarButtons()
        ThemeManager.apply(to: navigationController, traitCollection: traitCollection)
        navigationController?.navigationBar.layoutIfNeeded()
    }
    
    @objc private func openChecklists() {
        let vc = ChecklistMenuViewController()
        applyUserInterfaceStyle(to: vc)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func openCustomChecklists() {
        let vc = CustomChecklistListViewController()
        applyUserInterfaceStyle(to: vc)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func openFavorites() {
        let vc = FavoritesViewController()
        applyUserInterfaceStyle(to: vc)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func openContacts() {
        let vc = ContactsViewController()
        applyUserInterfaceStyle(to: vc)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func presentAboutViewController() {
        let about = AboutViewController()
        applyUserInterfaceStyle(to: about)
        let nav = UINavigationController(rootViewController: about)
        applyUserInterfaceStyle(to: nav)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }
    
    @objc private func presentHelpViewController() {
        let help = HelpViewController()
        applyUserInterfaceStyle(to: help)
        let nav = UINavigationController(rootViewController: help)
        applyUserInterfaceStyle(to: nav)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }
    
    // MARK: - Return Path Methods for Emergency SMS Flow
    
    func openProfileWithReturnPath(checklist: ChecklistInfo?, customChecklist: CustomChecklist?) {
        let settingsVC = SettingsViewController()
        settingsVC.cameFromPDFGeneration = false
        settingsVC.returnToChecklist = { [weak self] in
            DispatchQueue.main.async {
                self?.returnToChecklist(checklist: checklist, customChecklist: customChecklist)
            }
        }
        
        let nav = UINavigationController(rootViewController: settingsVC)
        ThemeManager.apply(to: nav, traitCollection: nav.traitCollection)
        present(nav, animated: true)
    }
    
    func openContactsWithReturnPath(checklist: ChecklistInfo?, customChecklist: CustomChecklist?) {
        let contactsVC = ContactsViewController()
        contactsVC.openToEmergencyCategory = true
        contactsVC.returnToChecklist = { [weak self] in
            DispatchQueue.main.async {
                self?.returnToChecklist(checklist: checklist, customChecklist: customChecklist)
            }
        }
        
        let nav = UINavigationController(rootViewController: contactsVC)
        ThemeManager.apply(to: nav, traitCollection: nav.traitCollection)
        present(nav, animated: true)
    }
    
    func openProfileWithPDFReturnPath(checklist: ChecklistInfo?, customChecklist: CustomChecklist?) {
        let settingsVC = SettingsViewController()
        settingsVC.cameFromPDFGeneration = false
        settingsVC.returnToChecklistForPDF = { [weak self] in
            DispatchQueue.main.async {
                self?.returnToChecklistAndGeneratePDF(checklist: checklist, customChecklist: customChecklist)
            }
        }
        
        let nav = UINavigationController(rootViewController: settingsVC)
        ThemeManager.apply(to: nav, traitCollection: nav.traitCollection)
        present(nav, animated: true)
    }
    
    private func returnToChecklist(checklist: ChecklistInfo?, customChecklist: CustomChecklist?) {
        let checklistVC = ChecklistViewController()
        checklistVC.checklist = checklist
        checklistVC.customChecklist = customChecklist
        navigationController?.pushViewController(checklistVC, animated: true)
    }
    
    private func returnToChecklistAndGeneratePDF(checklist: ChecklistInfo?, customChecklist: CustomChecklist?) {
        let checklistVC = ChecklistViewController()
        checklistVC.checklist = checklist
        checklistVC.customChecklist = customChecklist
        navigationController?.pushViewController(checklistVC, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            checklistVC.promptForVesselAndGeneratePDF()
        }
    }
    
    // MARK: – Utilities
    
    private func loadNightModePreference() {
        isNightMode = UserDefaults.standard.bool(forKey: "nightMode")
    }
    
    private func applyUserInterfaceStyle(to vc: UIViewController) {
        vc.overrideUserInterfaceStyle = isNightMode ? .dark : .light
    }
}
