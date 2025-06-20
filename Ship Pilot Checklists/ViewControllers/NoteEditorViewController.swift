//
//  NoteEditorViewController.swift
//  Ship Pilot Checklists
//
//  Created by Jill Russell on 5/31/25.
//

import UIKit

// STEP 1: Conform to the UITextViewDelegate protocol. This lets our
// view controller listen to events from the text view, like when a
// user starts or stops typing.
class NoteEditorViewController: UIViewController, UITextViewDelegate {

    private let textView = UITextView()
    
    // We no longer need the separate saveButton property, as it will be in the nav bar
    // private let saveButton = UIButton(type: .system)

    // NEW: Define our placeholder text and its color
    private let placeholderText = "Tap to enter note..."
    
    private var initialText: String?
    private var saveHandler: (String?) -> Void

    init(initial: String?, saveHandler: @escaping (String?)->Void) {
        self.initialText = initial
        self.saveHandler = saveHandler
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGroupedBackground // A better background for modal sheets

        // --- SETUP THE NAVIGATION BAR ---
        // We'll give this screen a title and add "Cancel" and "Save" buttons.
        self.title = "Edit Note"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveTapped))

        // --- CONFIGURE THE TEXT VIEW ---
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .systemFont(ofSize: 16)
        
        // STEP 2A: Style the "defined box"
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 8
        textView.layer.borderColor = UIColor.systemGray3.cgColor
        textView.layer.borderWidth = 1.0
        // Add a little padding so text isn't right up against the edge
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
        
        view.addSubview(textView)

        // Set ourselves as the delegate to listen for typing events
        textView.delegate = self
        
        // --- LAYOUT CONSTRAINTS ---
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            // Pin the text view to the safe area with some padding
            textView.topAnchor.constraint(equalTo: guide.topAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
            // Let's have it take up a good portion of the top of the screen
            textView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4)
        ])
        
        // This is the last step of viewDidLoad: set the initial state of the placeholder.
        setupPlaceholder()
    }

    // STEP 3: Make the keyboard appear automatically.
    // We do this in viewWillAppear, which is called right before the screen becomes visible.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // This tells the text view to become active and show the keyboard.
        textView.becomeFirstResponder()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // This ensures the border color updates correctly for light/dark mode changes.
        textView.layer.borderColor = UIColor.systemGray3.cgColor
    }

    // --- HELPER & ACTION METHODS ---

    private func setupPlaceholder() {
        // If there's existing text, show it with the normal text color.
        if let existingText = initialText, !existingText.isEmpty {
            textView.text = existingText
            textView.textColor = .label // .label is the standard text color
        } else {
            // Otherwise, show our placeholder text with a placeholder color.
            textView.text = placeholderText
            textView.textColor = .placeholderText
        }
    }

    @objc private func cancelTapped() {
        // Just dismiss the screen without saving.
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func saveTapped() {
        let trimmed: String
        
        // If the text view is still showing our placeholder, it means the user
        // didn't type anything. In that case, we save an empty string.
        if textView.textColor == .placeholderText {
            trimmed = ""
        } else {
            trimmed = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        let result: String? = trimmed.isEmpty ? nil : trimmed
        saveHandler(result)
        dismiss(animated: true, completion: nil)
    }
    
    // --- UITEXTVIEW DELEGATE METHODS ---
    // These two functions are the magic for our placeholder text.

    // STEP 2B: This is called when the user TAPS into the text view.
    func textViewDidBeginEditing(_ textView: UITextView) {
        // If the text view is currently showing our placeholder...
        if textView.textColor == .placeholderText {
            // ...then clear it and change the color to the normal editing color.
            textView.text = nil
            textView.textColor = .label
        }
    }

    // STEP 2C: This is called when the user TAPS AWAY from the text view.
    func textViewDidEndEditing(_ textView: UITextView) {
        // If the user tapped away and left it empty...
        if textView.text.isEmpty {
            // ...put the placeholder back.
            setupPlaceholder()
        }
    }
}
