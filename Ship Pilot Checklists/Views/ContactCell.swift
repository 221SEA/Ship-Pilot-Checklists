//
//  ContactCell.swift
//  Ship Pilot Checklists
//

import UIKit

class ContactCell: UITableViewCell {
    
    // MARK: - UI Elements
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    private let organizationLabel = UILabel()
    private let phoneLabel = UILabel()
    private let vhfLabel = UILabel()
    private let categoryLabel = UILabel()
    
    private let callButton = UIButton(type: .system)
    private let textButton = UIButton(type: .system)
    
    private let stackView = UIStackView()
    private let buttonStackView = UIStackView()
    
    // MARK: - Actions
    var callAction: (() -> Void)?
    var textAction: (() -> Void)?
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        // Configure stack view
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure labels
        nameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        nameLabel.numberOfLines = 1
        
        roleLabel.font = .systemFont(ofSize: 15)
        roleLabel.textColor = .secondaryLabel
        roleLabel.numberOfLines = 1
        
        organizationLabel.font = .systemFont(ofSize: 15)
        organizationLabel.textColor = .secondaryLabel
        organizationLabel.numberOfLines = 1
        
        phoneLabel.font = .systemFont(ofSize: 15)
        phoneLabel.numberOfLines = 1
        
        vhfLabel.font = .systemFont(ofSize: 13)
        vhfLabel.textColor = .tertiaryLabel
        vhfLabel.numberOfLines = 1
        
        categoryLabel.font = .systemFont(ofSize: 12)
        categoryLabel.textColor = .systemBlue
        categoryLabel.numberOfLines = 1
        
        // Configure buttons
        let callConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        callButton.setImage(UIImage(systemName: "phone", withConfiguration: callConfig), for: .normal)
        callButton.addTarget(self, action: #selector(callTapped), for: .touchUpInside)
        
        let textConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        textButton.setImage(UIImage(systemName: "message", withConfiguration: textConfig), for: .normal)
        textButton.addTarget(self, action: #selector(textTapped), for: .touchUpInside)
        
        // Configure button stack
        buttonStackView.axis = .vertical
        buttonStackView.spacing = 12
        buttonStackView.alignment = .center
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        
        buttonStackView.addArrangedSubview(callButton)
        buttonStackView.addArrangedSubview(textButton)
        
        // Add labels to stack view
        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(roleLabel)
        stackView.addArrangedSubview(organizationLabel)
        stackView.addArrangedSubview(phoneLabel)
        stackView.addArrangedSubview(vhfLabel)
        stackView.addArrangedSubview(categoryLabel)
        
        // Add to content view
        contentView.addSubview(stackView)
        contentView.addSubview(buttonStackView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
            stackView.trailingAnchor.constraint(equalTo: buttonStackView.leadingAnchor, constant: -12),
            
            buttonStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            buttonStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            buttonStackView.widthAnchor.constraint(equalToConstant: 44),
            
            // Add minimum height constraint to ensure buttons are never cut off
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 88)
        ])
    }
    
    // MARK: - Configuration
    func configure(with contact: OperationalContact, category: String?, traitCollection: UITraitCollection) {
        // Set text
        nameLabel.text = contact.name
        
        // Role and organization on same line if both exist
        var roleOrgText = ""
        if let role = contact.role, !role.isEmpty {
            roleOrgText = role
        }
        if let org = contact.organization, !org.isEmpty {
            roleOrgText = roleOrgText.isEmpty ? org : "\(roleOrgText) - \(org)"
        }
        
        roleLabel.text = roleOrgText
        roleLabel.isHidden = roleOrgText.isEmpty
        
        // Phone
        phoneLabel.text = contact.phone
        
        // VHF Channel
        if let vhf = contact.vhfChannel, !vhf.isEmpty {
            vhfLabel.text = "VHF: \(vhf)"
            vhfLabel.isHidden = false
        } else {
            vhfLabel.isHidden = true
        }
        
        // Category label (only shown in search results)
        if let cat = category {
            categoryLabel.text = cat
            categoryLabel.isHidden = false
        } else {
            categoryLabel.isHidden = true
        }
        
        // Update colors based on theme
        let titleColor = ThemeManager.titleColor(for: traitCollection)
        nameLabel.textColor = titleColor
        phoneLabel.textColor = titleColor
        callButton.tintColor = ThemeManager.themeColor
        textButton.tintColor = ThemeManager.themeColor
        
        // Hide organization label if not needed
        organizationLabel.isHidden = true
    }
    
    // MARK: - Actions
    @objc private func callTapped() {
        callAction?()
    }
    
    @objc private func textTapped() {
        textAction?()
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        roleLabel.text = nil
        organizationLabel.text = nil
        phoneLabel.text = nil
        vhfLabel.text = nil
        categoryLabel.text = nil
        
        roleLabel.isHidden = false
        organizationLabel.isHidden = true
        vhfLabel.isHidden = true
        categoryLabel.isHidden = true
    }
}
