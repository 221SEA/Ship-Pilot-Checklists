//
//  UIColor+Hex.swift
//  Ship Pilot Checklists
//
//  Created by Jill Russell on 5/26/25.
//

import UIKit

extension UIColor {
    /// Initialize UIColor with hex value and optional alpha
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let red   = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hex & 0x00FF00) >> 8) / 255.0
        let blue  = CGFloat(hex & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
