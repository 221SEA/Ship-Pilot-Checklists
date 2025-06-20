//
//  CustomChecklistMenuCell.swift
//  Ship Pilot Checklists
//
//  This is the final, corrected version with layout fixes.
//

import UIKit

class CustomChecklistMenuCell: UITableViewCell {

    let titleLabel = UILabel()
    let editButton = UIButton(type: .system)
    let favoriteButton = UIButton(type: .system)

    var editTapped: (() -> Void)?
    var favoriteTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // --- TEXT WRAPPING & FONT SIZE ---
        titleLabel.numberOfLines = 0
        titleLabel.font = .systemFont(ofSize: 18, weight: .medium)
        
        let stackView = UIStackView(arrangedSubviews: [favoriteButton, editButton])
        stackView.spacing = 12
        
        // --- Layout ---
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        contentView.addSubview(stackView)
        
        // --- LAYOUT FIX ---
        // These constraints correctly pin the label to the left and the buttons to the right.
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            // Allow the title to grow, but stop it before it hits the buttons.
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: stackView.leadingAnchor, constant: -8),

            // Pin the stack of buttons to the right side of the cell.
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
        ])
        
        editButton.addTarget(self, action: #selector(editTappedAction), for: .touchUpInside)
        favoriteButton.addTarget(self, action: #selector(favoriteTappedAction), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with checklist: CustomChecklist, traitCollection: UITraitCollection) {
        titleLabel.text = checklist.title
        
        let starIcon = checklist.isFavorite ? "star.fill" : "star"
        favoriteButton.setImage(UIImage(systemName: starIcon), for: .normal)
        editButton.setImage(UIImage(systemName: "pencil"), for: .normal)
        
        // Explicitly set the text and button colors using the ThemeManager
        let tint = ThemeManager.titleColor(for: traitCollection)
        titleLabel.textColor = tint
        favoriteButton.tintColor = tint
        editButton.tintColor = tint
    }

    @objc func editTappedAction() { editTapped?() }
    @objc func favoriteTappedAction() { favoriteTapped?() }
}
