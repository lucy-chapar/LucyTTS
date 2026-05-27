import SwiftUI

enum LucyTheme {
    static let blush = Color(red: 1.0, green: 0.75, blue: 0.81)
    static let blushDeep = Color(red: 0.96, green: 0.48, blue: 0.62)
    static let cream = Color(red: 1.0, green: 0.92, blue: 0.77)
    static let plum = Color(red: 0.13, green: 0.05, blue: 0.16)
    static let hotPink = Color(red: 0.95, green: 0.26, blue: 0.58)
    static let olive = Color(red: 0.30, green: 0.36, blue: 0.20)
    static let silver = Color(red: 0.70, green: 0.70, blue: 0.68)

    static let background = LinearGradient(
        colors: [blush, Color(red: 1.0, green: 0.86, blue: 0.88)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
