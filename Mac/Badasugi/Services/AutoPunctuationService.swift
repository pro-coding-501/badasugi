import Foundation

/// Lightweight, local-only auto punctuation for transcripts when the provider doesn't add punctuation.
/// Intentionally conservative: adds punctuation mainly at the end so it won't over-edit content.
struct AutoPunctuationService {
    /// Applies auto punctuation to the given text.
    /// - Note: This is heuristic-based. It should be safe and predictable rather than "smart".
    static func apply(to text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }

        // If it already ends with a terminal punctuation mark, keep as-is.
        if endsWithTerminalPunctuation(trimmed) {
            return trimmed
        }

        // Avoid adding punctuation after certain trailing characters.
        // e.g. if it ends with a quote/bracket, still consider adding punctuation before it in future.
        // For now, keep it simple and append at the very end.
        let punctuation: String = inferTerminalPunctuation(for: trimmed)
        return trimmed + punctuation
    }

    private static func endsWithTerminalPunctuation(_ text: String) -> Bool {
        // Common terminal punctuation across languages.
        let terminals: [Character] = [".", "!", "?", "…", "。", "！", "？"]
        guard let last = text.last else { return false }
        return terminals.contains(last)
    }

    private static func inferTerminalPunctuation(for text: String) -> String {
        // Korean question-style endings (heuristic).
        // This is intentionally narrow to avoid turning statements into questions.
        let koreanQuestionEndings = [
            "까요", "니까", "나요", "니", "냐", "습니까", "인가요", "죠", "지요"
        ]

        for ending in koreanQuestionEndings {
            if text.hasSuffix(ending) {
                return "?"
            }
        }

        // Default to a period.
        return "."
    }
}


