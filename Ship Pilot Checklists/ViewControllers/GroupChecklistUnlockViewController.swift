import UIKit

class GroupChecklistUnlockViewController: UIViewController {

    // MARK: - UI

    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter your group access code:"
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let codeTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "e.g. PSP2025"
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .allCharacters
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let unlockButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Unlock", for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        btn.backgroundColor = ThemeManager.themeColor
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 8
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1) let your view stretch full-screen under nav & home bar
        edgesForExtendedLayout = [.all]
        extendedLayoutIncludesOpaqueBars = true

        // 2) day/night & theming
        overrideUserInterfaceStyle = UserDefaults.standard.bool(forKey: "nightMode")
            ? .dark : .light
        title = "My Group Checklists"
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)

        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.setNeedsLayout()
        navigationController?.navigationBar.layoutIfNeeded()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        view.backgroundColor = ThemeManager.backgroundColor(for: traitCollection)
        ThemeManager.apply(to: navigationController, traitCollection: traitCollection)
    }

    // MARK: - Layout

    private func setupUI() {
        view.addSubview(instructionLabel)
        view.addSubview(codeTextField)
        view.addSubview(unlockButton)

        NSLayoutConstraint.activate([
            // now anchored to the very top of your view
            instructionLabel.topAnchor.constraint(
                equalTo: view.topAnchor, constant: 100),
            instructionLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -20),

            codeTextField.topAnchor.constraint(
                equalTo: instructionLabel.bottomAnchor, constant: 20),
            codeTextField.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 40),
            codeTextField.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -40),
            codeTextField.heightAnchor.constraint(equalToConstant: 44),

            unlockButton.topAnchor.constraint(
                equalTo: codeTextField.bottomAnchor, constant: 30),
            unlockButton.centerXAnchor.constraint(
                equalTo: view.centerXAnchor),
            unlockButton.widthAnchor.constraint(equalToConstant: 140),
            unlockButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        unlockButton.addTarget(
            self,
            action: #selector(handleUnlock),
            for: .touchUpInside
        )
    }

    // MARK: - Actions

    @objc private func handleUnlock() {
        guard let code = codeTextField.text?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased(),
              !code.isEmpty
        else {
            showAlert("Please enter a group code.")
            return
        }

        if let groupChecklists = GroupChecklists.all[code] {
            UserDefaults.standard.set(code, forKey: "unlockedGroupCode")
            let groupVC = GroupChecklistListViewController()
            groupVC.groupCode = code
            groupVC.checklists = groupChecklists
            navigationController?.pushViewController(groupVC, animated: true)
        } else {
            showAlert("Invalid code. Please check with your group leader.")
        }
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(
            title: "Oops",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(title: "OK", style: .default)
        )
        present(alert, animated: true)
    }
}
