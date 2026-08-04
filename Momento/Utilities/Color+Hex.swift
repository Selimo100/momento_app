import SwiftUI
import UIKit

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = (int >> 16) & 0xFF
        let g = (int >> 8) & 0xFF
        let b = int & 0xFF
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }

    var hexString: String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(
            format: "%02x%02x%02x",
            min(255, Int(r * 255)),
            min(255, Int(g * 255)),
            min(255, Int(b * 255))
        )
    }
}
