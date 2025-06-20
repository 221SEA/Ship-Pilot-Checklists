//
//  FavoriteCell.swift
//  Ship Pilot Checklists
//

import UIKit

class FavoriteCell: UITableViewCell {
    
    let titleLabel = UILabel()
    let starButton = UIButton(type: .system)
    
    var unfavoriteTapped: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // Allow wrapping for long checklist names
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode   = .byWordWrapping
        titleLabel.font = .systemFont(ofSize: 18, weight: .medium)
        
        // Add star button action
        starButton.addTarget(self, action: #selector(didTapStar), for: .touchUpInside)
        
        // --- Layout ---
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        starButton.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(starButton)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            starButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            starButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            starButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            starButton.widthAnchor.constraint(equalToConstant: 24),
            starButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    func configure(with title: String?, isNightMode: Bool) {
        titleLabel.text = title
        
        // Always show a filled star in favorites
        starButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
        
        // Use the ThemeManager to set the correct color for day/night mode
        let themeTrait = isNightMode ? UITraitCollection(userInterfaceStyle: .dark) : UITraitCollection(userInterfaceStyle: .light)
        let color = ThemeManager.titleColor(for: themeTrait)
        
        titleLabel.textColor = color
        starButton.tintColor = color
    }
    
    @objc private func didTapStar() {
        unfavoriteTapped?()
    }
}
