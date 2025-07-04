//
//  ChecklistInfo+ConvertToCustom.swift
//  Ship Pilot Checklists
//
//  Created by Jill Russell on 5/25/25.
//


import Foundation

extension ChecklistInfo {
    func convertToCustom() -> CustomChecklist {
        return CustomChecklist(
            id: UUID(),
            title: self.title,
            sections: self.sections
        )
    }
}
