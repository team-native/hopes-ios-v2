import UIKit

enum ChatMarkdownBlock: Equatable {
    case heading(String)
    case paragraph(String)
    case orderedList([String])
    case bulletList([String])
    case code(language: String, text: String)
    case quote(String)
    case link(title: String, url: URL)
}

enum ChatMarkdownParser {
    static func parse(_ markdown: String) -> [ChatMarkdownBlock] {
        var state = ChatMarkdownParseState()
        for rawLine in markdown.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n") {
            state.consume(rawLine)
        }
        return state.finish()
    }

    static func orderedItem(_ line: String) -> String? {
        guard let dot = line.firstIndex(of: "."), line[..<dot].allSatisfy(\.isNumber), !line[..<dot].isEmpty else {
            return nil
        }
        let rest = line[line.index(after: dot)...]
        guard rest.first == " " else { return nil }
        return rest.trimmingCharacters(in: .whitespaces)
    }

    static func standaloneLink(_ line: String) -> ChatMarkdownBlock? {
        guard line.hasPrefix("["), line.hasSuffix(")"),
              let middle = line.range(of: "]("),
              let url = URL(string: String(line[middle.upperBound..<line.index(before: line.endIndex)])),
              ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return nil }
        let title = String(line[line.index(after: line.startIndex)..<middle.lowerBound])
        return .link(title: title, url: url)
    }
}

struct ChatMarkdownParseState {
    private(set) var blocks: [ChatMarkdownBlock] = []
    private var paragraph: [String] = []
    private var ordered: [String] = []
    private var bullets: [String] = []
    private var quote: [String] = []
    private var code: (language: String, lines: [String])?

    mutating func consume(_ rawLine: String) {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if code != nil {
            consumeCode(rawLine, trimmed: line)
            return
        }
        if line.hasPrefix("```") {
            flush()
            code = (String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces), [])
        } else if line.isEmpty {
            flush()
        } else if line.hasPrefix("#") {
            flush()
            let text = line.drop { $0 == "#" }.trimmingCharacters(in: .whitespaces)
            if !text.isEmpty { blocks.append(.heading(text)) }
        } else {
            consumeInline(line)
        }
    }

    mutating func finish() -> [ChatMarkdownBlock] {
        if let code { blocks.append(.code(language: code.language, text: code.lines.joined(separator: "\n"))) }
        code = nil
        flush()
        return blocks
    }

    private mutating func consumeCode(_ rawLine: String, trimmed: String) {
        guard var current = code else { return }
        if trimmed.hasPrefix("```") {
            blocks.append(.code(language: current.language, text: current.lines.joined(separator: "\n")))
            code = nil
        } else {
            current.lines.append(rawLine)
            code = current
        }
    }

    private mutating func consumeInline(_ line: String) {
        if line.hasPrefix(">") {
            if quote.isEmpty { flush() }
            quote.append(line.dropFirst().trimmingCharacters(in: .whitespaces))
        } else if let item = ChatMarkdownParser.orderedItem(line) {
            if ordered.isEmpty { flush() }
            ordered.append(item)
        } else if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("• ") {
            if bullets.isEmpty { flush() }
            bullets.append(String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces))
        } else if let link = ChatMarkdownParser.standaloneLink(line) {
            flush()
            blocks.append(link)
        } else {
            if !ordered.isEmpty || !bullets.isEmpty || !quote.isEmpty { flush() }
            paragraph.append(line)
        }
    }

    private mutating func flush() {
        if !paragraph.isEmpty { blocks.append(.paragraph(paragraph.joined(separator: "\n"))); paragraph = [] }
        if !ordered.isEmpty { blocks.append(.orderedList(ordered)); ordered = [] }
        if !bullets.isEmpty { blocks.append(.bulletList(bullets)); bullets = [] }
        if !quote.isEmpty { blocks.append(.quote(quote.joined(separator: "\n"))); quote = [] }
    }
}

@MainActor
extension ChatConversationViewController {
    func makeMarkdownAnswerStack(_ markdown: String) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        for block in ChatMarkdownParser.parse(markdown) {
            stack.addArrangedSubview(makeMarkdownView(block))
        }
        return stack
    }

    private func markdownLabel(_ text: String, size: CGFloat, lineHeight: CGFloat,
                               color: UIColor = ChatDetailPalette.ink) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        let attributed = NSMutableAttributedString(attributedString: MarkdownText.attributed(text, size: size,
            color: color))
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
        let range = NSRange(location: 0, length: attributed.length)
        attributed.addAttribute(.paragraphStyle, value: paragraph, range: range)
        label.attributedText = attributed
        return label
    }

    private func makeMarkdownView(_ block: ChatMarkdownBlock) -> UIView {
        switch block {
        case let .heading(text):
            let label = markdownLabel(text, size: 18, lineHeight: 26)
            label.font = .systemFont(ofSize: 18, weight: .medium)
            return label
        case let .paragraph(text):
            return markdownLabel(text, size: 15, lineHeight: 24)
        case let .orderedList(items):
            return makeMarkdownList(items.enumerated().map { ("\($0.offset + 1).", $0.element) })
        case let .bulletList(items):
            return makeMarkdownList(items.map { ("•", $0) })
        case let .code(language, text):
            return makeMarkdownCodeCard(language: language, code: text)
        case let .quote(text):
            return makeMarkdownQuote(text)
        case let .link(title, url):
            return makeMarkdownLink(title: title, url: url)
        }
    }

    private func makeMarkdownList(_ items: [(String, String)]) -> UIView {
        let list = UIStackView()
        list.axis = .vertical
        list.spacing = 4
        for (marker, text) in items {
            let number = markdownLabel(marker, size: 15, lineHeight: 24, color: ChatDetailPalette.brand)
            number.font = .systemFont(ofSize: 15, weight: .medium)
            number.setContentHuggingPriority(.required, for: .horizontal)
            number.setContentCompressionResistancePriority(.required, for: .horizontal)
            let body = markdownLabel(text, size: 15, lineHeight: 24)
            let row = UIStackView(arrangedSubviews: [number, body])
            row.axis = .horizontal
            row.alignment = .top
            row.spacing = 8
            list.addArrangedSubview(row)
        }
        return list
    }

    private func makeMarkdownCodeCard(language: String, code: String) -> UIView {
        let card = UIView()
        card.backgroundColor = AppStyle.canvas
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = AppStyle.line.cgColor
        let languageLabel = AppStyle.label(language.isEmpty ? "code" : language, size: 12, color: AppStyle.muted)
        let copy = UIButton(type: .custom)
        copy.setImage(UIImage(named: "ChatAnswerCopy")?.withRenderingMode(.alwaysOriginal), for: .normal)
        copy.accessibilityLabel = "코드 복사"
        copy.addAction(UIAction { [weak self] _ in
            UIPasteboard.general.string = code
            self?.showToast("코드를 복사했어요")
        }, for: .touchUpInside)
        let header = UIStackView(arrangedSubviews: [languageLabel, UIView(), copy])
        header.axis = .horizontal
        header.alignment = .center
        let codeLabel = AppStyle.label(code, size: 12)
        codeLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        let stack = UIStackView(arrangedSubviews: [header, codeLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            copy.widthAnchor.constraint(equalToConstant: 28),
            copy.heightAnchor.constraint(equalToConstant: 28),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10)
        ])
        return card
    }

    private func makeMarkdownQuote(_ text: String) -> UIView {
        let label = markdownLabel(text, size: 14, lineHeight: 20, color: ChatDetailPalette.muted)
        let line = UIView()
        line.backgroundColor = AppStyle.blue.withAlphaComponent(0.45)
        let row = UIView()
        row.addSubview(line)
        row.addSubview(label)
        line.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            line.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            line.topAnchor.constraint(equalTo: row.topAnchor),
            line.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            line.widthAnchor.constraint(equalToConstant: 3),
            label.leadingAnchor.constraint(equalTo: line.trailingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            label.topAnchor.constraint(equalTo: row.topAnchor, constant: 2),
            label.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -2)
        ])
        return row
    }

    private func makeMarkdownLink(title: String, url: URL) -> UIView {
        let button = UIButton(type: .custom)
        button.setAttributedTitle(NSAttributedString(string: title, attributes: [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: ChatDetailPalette.brand,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]), for: .normal)
        button.contentHorizontalAlignment = .leading
        button.titleLabel?.numberOfLines = 0
        button.accessibilityTraits = .link
        button.addAction(UIAction { _ in UIApplication.shared.open(url) }, for: .touchUpInside)
        return button
    }
}

final class ChatAnswerCopyGesture: UILongPressGestureRecognizer {
    private let markdown: String
    private let onCopy: (String) -> Void

    init(markdown: String, onCopy: @escaping (String) -> Void) {
        self.markdown = markdown
        self.onCopy = onCopy
        super.init(target: nil, action: nil)
        addTarget(self, action: #selector(handle))
    }

    @objc private func handle() {
        guard state == .began else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onCopy(Self.plainText(from: markdown))
    }

    static func plainText(from markdown: String) -> String {
        ChatMarkdownParser.parse(markdown).map { block in
            switch block {
            case let .heading(text), let .paragraph(text), let .quote(text): text
            case let .orderedList(items): items.enumerated().map { "\($0.offset + 1). \($0.element)" }
                .joined(separator: "\n")
            case let .bulletList(items): items.map { "• \($0)" }.joined(separator: "\n")
            case let .code(_, text): text
            case let .link(title, url): "\(title) \(url.absoluteString)"
            }
        }
        .joined(separator: "\n\n")
        .replacingOccurrences(of: "**", with: "")
    }
}
