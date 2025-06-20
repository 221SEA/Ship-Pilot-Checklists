import UIKit

class DisclaimerViewController: UIViewController {
    
    private let disclaimerTextView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isEditable = false
        
        // Increase font for readability
        tv.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        tv.text = """
        Please read and acknowledge the following disclaimer:
        
        This application and all included checklists are provided for reference only and do not constitute official procedures or professional advice. The user assumes full responsibility for verifying the accuracy, completeness, and appropriateness of all checklist content for their specific operations, vessel, and circumstances.
        
        By using this app, you acknowledge that you are solely responsible for the use, customization, and outcomes of any checklist, including those provided by default. You agree that you have reviewed each checklist and adopted them as your own. Use of the app implies acceptance of this ownership.
        
        The developers and publishers of this app disclaim all liability for any loss, damage, or injury resulting from the use or misuse of this app or any checklist in this app, including omissions or errors in checklist content. Nothing in the development or provision of this app and accompanying checklists relieves the user of the responsibility to exercise professional judgement and the reasonable care and diligence required of a prudent mariner and to comply with all applicable regulatory requirements and guidelines.
        
        By tapping "I Agree", you confirm that you have read and understand this disclaimer.
        """
        return tv
    }()
    
    private let agreeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("I Agree", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        btn.layer.cornerRadius = 8
        btn.contentEdgeInsets = .init(top: 12, left: 24, bottom: 12, right: 24)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Allow content to go under translucent bars, then push down via safeArea
        edgesForExtendedLayout = [.all]
        extendedLayoutIncludesOpaqueBars = true
        
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        
        setupViews()
        applyTheme()
        
        agreeButton.addTarget(self, action: #selector(agreeButtonTapped), for: .touchUpInside)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        applyTheme()
    }
    
    private func applyTheme() {
        let textColor = ThemeManager.titleColor(for: traitCollection)
        disclaimerTextView.textColor = textColor
        agreeButton.setTitleColor(textColor, for: .normal)
    }
    
    private func setupViews() {
        view.addSubview(disclaimerTextView)
        view.addSubview(agreeButton)
        
        NSLayoutConstraint.activate([
            // Pin top of textView to safeArea, not directly to view.topAnchor
            disclaimerTextView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            disclaimerTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            disclaimerTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            disclaimerTextView.bottomAnchor.constraint(equalTo: agreeButton.topAnchor, constant: -20),
            
            // Button sits just above safeArea bottom
            agreeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            agreeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    @objc private func agreeButtonTapped() {
        UserDefaults.standard.set(true, forKey: "disclaimerAgreed")
        
        dismiss(animated: true) { [weak self] in
            // After disclaimer is dismissed, check if we should prompt for profile setup
            self?.checkForProfileSetupPrompt()
        }
    }
    
    private func checkForProfileSetupPrompt() {
        // Check if user has already set up basic profile info
        let pilotName = UserDefaults.standard.string(forKey: "pilotName") ?? ""
        let hasContacts = UserDefaults.standard.data(forKey: "emergencyContacts") != nil
        
        // If they haven't set up basic info, prompt them
        if pilotName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !hasContacts {
            let alert = UIAlertController(
                title: "Set Up Profile?",
                message: "Would you like to set up your pilot profile now? This enables emergency SMS and PDF features.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Skip for Now", style: .cancel))
            
            alert.addAction(UIAlertAction(title: "Set Up Now", style: .default) { _ in
                // Navigate to profile
                if let window = UIApplication.shared.windows.first,
                   let navController = window.rootViewController as? UINavigationController,
                   let mainVC = navController.topViewController as? MainViewController {
                    mainVC.openProfile()
                }
            })
            
            // Present from the main view controller
            if let window = UIApplication.shared.windows.first,
               let navController = window.rootViewController as? UINavigationController,
               let mainVC = navController.topViewController as? MainViewController {
                mainVC.present(alert, animated: true)
            }
        }
    }
}
