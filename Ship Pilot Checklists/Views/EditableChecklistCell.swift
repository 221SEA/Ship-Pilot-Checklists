//
//  EditableChecklistCell.swift
//  Ship Pilot Checklists
//

import UIKit
import Foundation   // so we pick up the global ChecklistItem

/// A single row in “Custom Checklist Editor” where you can drag/reorder and edit text.
class EditableChecklistCell: UITableViewCell {

    let dragHandle = UIImageView()
    let textField = UITextField()
    let deleteButton = UIButton(type: .system)

    var textChanged: ((String) -> Void)?
    var deleteTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        preservesSuperviewLayoutMargins = false
        separatorInset = .zero
        layoutMargins = .zero
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        // 1) Drag-handle icon on left
        dragHandle.translatesAutoresizingMaskIntoConstraints = false
        dragHandle.image = UIImage(systemName: "line.3.horizontal")
        dragHandle.tintColor = .systemGray
        dragHandle.contentMode = .scaleAspectFit

        // 2) Text field (middle)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .roundedRect
        textField.placeholder = "Checklist item"
        textField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)

        // 3) Delete button on right
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)

        // Add subviews
        contentView.addSubview(dragHandle)
        contentView.addSubview(textField)
        contentView.addSubview(deleteButton)

        // Auto Layout
        NSLayoutConstraint.activate([
            dragHandle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            dragHandle.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            dragHandle.widthAnchor.constraint(equalToConstant: 20),
            dragHandle.heightAnchor.constraint(equalToConstant: 20),

            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            deleteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 28),
            deleteButton.heightAnchor.constraint(equalToConstant: 28),

            textField.leadingAnchor.constraint(equalTo: dragHandle.trailingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -12),
            textField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textField.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    /// Configure with the model ChecklistItem (we only use `item.title` here)
    public func configure(with item: ChecklistItem) {
        textField.text = item.title
        showsReorderControl = false
        textField.textColor = ThemeManager.titleColor(for: traitCollection)
    }

    @objc private func textFieldChanged() {
        textChanged?(textField.text ?? "")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        textField.textColor = ThemeManager.titleColor(for: traitCollection)
    }

    @objc private func deleteButtonTapped() {
        deleteTapped?()
    }
}
