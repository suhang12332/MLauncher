//
//  Utils.swift
//  MLauncher
//
//  Created by su on 2025/6/8.
//
import SwiftUI
// MARK: - Extensions
extension Date {
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}
