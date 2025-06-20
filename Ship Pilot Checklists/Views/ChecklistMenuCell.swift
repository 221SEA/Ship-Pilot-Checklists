//
//  ChecklistMenuCell.swift
//  Ship Pilot Checklists
//

import UIKit

class ChecklistMenuCell: UITableViewCell {

    let titleLabel = UILabel()
    let favoriteButton = UIButton(type: .system)
    let addButton = UIButton(type: .system)

    var favoriteTapped: (() -> Void)?
    var addTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // --- TEXT WRAPPING & FONT SIZE ---
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode   = .byWordWrapping
        titleLabel.font = .systemFont(ofSize: 18, weight: .medium)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [favoriteButton, addButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 12

        // ←←← INSERT THESE PRIORITY TWEAKS ↓↓↓
        // Let the label wrap before buttons get squeezed:
        titleLabel.setContentHuggingPriority(.defaultLow,            for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        // Force the button stack to stay its intrinsic width:
        stackView.setContentHuggingPriority(.required,               for: .horizontal)
        stackView.setContentCompressionResistancePriority(.required,   for: .horizontal)
        // ←←← END INSERT
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(stackView)
        
        // --- LAYOUT FIX ---
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            // Allow the title to grow, but stop it before it hits the buttons.
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: stackView.leadingAnchor, constant: -8),
            
            // Pin the stack of buttons to the right side of the cell.
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        
        favoriteButton.addTarget(self, action: #selector(didTapFavorite), for: .touchUpInside)
        addButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with checklist: ChecklistInfo, traitCollection: UITraitCollection) {
        titleLabel.text = checklist.title
        
        // Use our new FavoritesManager to check the status
        let isFavorited = FavoritesManager.isFavorite(checklistTitle: checklist.title)
        let favIconName = isFavorited ? "star.fill" : "star"
        favoriteButton.setImage(UIImage(systemName: favIconName), for: .normal)
        
        // --- ICON FIX ---
        // Use the correct icon name here.
        addButton.setImage(UIImage(systemName: "pencil.and.list.clipboard"), for: .normal)
        
        let tint = ThemeManager.titleColor(for: traitCollection)
        titleLabel.textColor = tint
        favoriteButton.tintColor = tint
        addButton.tintColor = tint
    }
    
    @objc private func didTapFavorite() { favoriteTapped?() }
    @objc private func didTapAdd() { addTapped?() }
}
