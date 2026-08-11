import UIKit

enum VXColor {
    static let lime = UIColor(hex: 0xC8FF37)
    static let deepLime = UIColor(hex: 0xAEEA19)
    static let paleLime = UIColor(hex: 0xEEFDC1)
    static let softGreen = UIColor(hex: 0xECF2DA)
    static let ink = UIColor(hex: 0x050505)
    static let textSecondary = UIColor(hex: 0x70776B)
    static let textMuted = UIColor(hex: 0x939788)
    static let canvas = UIColor(hex: 0xFDFCFC)
    static let canvasAlt = UIColor(hex: 0xF9F8F7)
    static let surface = UIColor.white
    static let warning = UIColor(hex: 0xFF2D55)
}

enum VXFont {
    static func display(_ size: CGFloat = 32) -> UIFont { .systemFont(ofSize: size, weight: .bold) }
    static func title(_ size: CGFloat = 24) -> UIFont { .systemFont(ofSize: size, weight: .bold) }
    static func body(_ size: CGFloat = 14, weight: UIFont.Weight = .regular) -> UIFont { .systemFont(ofSize: size, weight: weight) }
}

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 255) / 255,
                  green: CGFloat((hex >> 8) & 255) / 255,
                  blue: CGFloat(hex & 255) / 255,
                  alpha: alpha)
    }
}

extension UIView {
    func vxRound(_ radius: CGFloat) { layer.cornerRadius = radius; layer.masksToBounds = true }
}

extension UIViewController {
    func vxAlert(title: String, message: String, actions: [(String, UIAlertAction.Style, (() -> Void)?)]) {
        let alert = VXAlertViewController(title: title, message: message, actions: actions.map { ($0.0, $0.1, $0.2) })
        present(alert, animated: true)
    }
}
