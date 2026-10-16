import Foundation

/// The page Hover opens at launch, chosen in Settings.
enum StartPage: String, CaseIterable {
    case watchLater
    case home
    case custom

    static let watchLaterURL = URL(string: "https://www.youtube.com/playlist?list=WL")!
    static let homeURL = URL(string: "https://www.youtube.com/")!

    private static let choiceKey = "startPage"
    private static let customURLKey = "startPageCustomURL"

    var title: String {
        switch self {
        case .watchLater: return "Watch Later"
        case .home: return "YouTube Home"
        case .custom: return "A Specific Page"
        }
    }

    static var current: StartPage {
        get { StartPage(rawValue: UserDefaults.standard.string(forKey: choiceKey) ?? "") ?? .watchLater }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: choiceKey) }
    }

    /// The address typed for "A Specific Page", kept as typed so the field shows it back.
    static var customAddress: String {
        get { UserDefaults.standard.string(forKey: customURLKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: customURLKey) }
    }

    /// Accepts only YouTube addresses, so a typo can't point the player somewhere else.
    /// A missing scheme is filled in ("youtube.com/watch?v=…" works).
    static func youTubeURL(from text: String) -> URL? {
        var address = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !address.contains("://") { address = "https://" + address }
        guard let url = URL(string: address),
              let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http",
              let host = url.host?.lowercased() else { return nil }
        let isYouTube = host == "youtube.com" || host.hasSuffix(".youtube.com") || host == "youtu.be"
        return isYouTube ? url : nil
    }

    /// The address to open now. An empty or non-YouTube custom page falls back to Watch Later.
    static var resolvedURL: URL {
        switch current {
        case .watchLater: return watchLaterURL
        case .home: return homeURL
        case .custom: return youTubeURL(from: customAddress) ?? watchLaterURL
        }
    }
}
