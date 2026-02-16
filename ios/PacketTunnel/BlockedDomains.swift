import Foundation

struct BlockedDomains {
    static let list: Set<String> = [
        // Social media
        "instagram.com",
        "cdninstagram.com",
        "tiktok.com",
        "tiktokcdn.com",
        "musical.ly",
        "twitter.com",
        "x.com",
        "facebook.com",
        "reddit.com",
        "snapchat.com",
        "threads.net",
        "bsky.app",
        "bsky.social",
        // "youtube.com", // Toggle: uncomment to block YouTube

        // Gambling
        "kalshi.com",
        "polymarket.com",

        // AI
        "chatgpt.com",
        "chat.openai.com",
        "openai.com",
        "gemini.google.com",
        "bard.google.com",
        "anthropic.com",
        "claude.ai",
    ]

    static func isBlocked(_ domain: String) -> Bool {
        let lowered = domain.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        for blocked in list {
            if lowered == blocked || lowered.hasSuffix("." + blocked) {
                return true
            }
        }
        return false
    }
}
