import Foundation

enum AppInfo {
    /// Shown in the intro line. Keep in sync with CFBundleDisplayName in project.yml.
    static let name = "dark weather"

    static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
}
