//
//  Common.swift
//  MLauncher
//
//  Created by su on 2025/6/28.
//
import SwiftUI
struct CommonUtil {
    // MARK: - Base64 图片解码工具
    static func imageFromBase64(_ base64: String) -> NSImage? {
        if base64.hasPrefix("data:image") {
            if let base64String = base64.split(separator: ",").last,
               let imageData = Data(base64Encoded: String(base64String)),
               let nsImage = NSImage(data: imageData) {
                return nsImage
            }
        } else if let imageData = Data(base64Encoded: base64),
                  let nsImage = NSImage(data: imageData) {
            return nsImage
        }
        return nil
    }

}
