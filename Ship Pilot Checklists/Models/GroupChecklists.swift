//
//  GroupChecklists.swift
//  Ship Pilot Checklists
//

import Foundation

enum GroupChecklists {
    static let all: [String: [ChecklistInfo]] = [
        "PSP2025": [
            ChecklistInfo(
                title: "PSP Emergency Protocol",
                category: .emergency,
                sections: [
                    ChecklistSection(title: "High Priority", items: [
                        ChecklistItem(title: "Secure the bridge", isChecked: false, timestamp: nil),
                        ChecklistItem(title: "Notify dispatch", isChecked: false, timestamp: nil)
                    ]),
                    ChecklistSection(title: "Medium Priority", items: [
                        ChecklistItem(title: "Log position", isChecked: false, timestamp: nil)
                    ]),
                    ChecklistSection(title: "Low Priority", items: [
                        ChecklistItem(title: "Record weather conditions", isChecked: false, timestamp: nil)
                    ])
                ]
            )
        ],

        "SFBP2025": [
            ChecklistInfo(
                title: "San Francisco Docking Checklist",
                category: .standard,
                sections: [
                    ChecklistSection(title: "High Priority", items: [
                        ChecklistItem(title: "Review docking charts", isChecked: false, timestamp: nil)
                    ]),
                    ChecklistSection(title: "Medium Priority", items: [
                        ChecklistItem(title: "Test local comms", isChecked: false, timestamp: nil)
                    ]),
                    ChecklistSection(title: "Low Priority", items: [
                        ChecklistItem(title: "Standby tugs", isChecked: false, timestamp: nil)
                    ])
                ]
            )
        ]
        // ✅ Add more group codes and checklists here
    ]
}
