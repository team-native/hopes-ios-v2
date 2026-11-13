import UIKit

@MainActor
final class CommunitySearchViewController: AppPageViewController, UITextFieldDelegate {
    let brandBlue = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
    let secondary = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
    let tertiary = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
    let searchFieldIcon = UIImageView(image: UIImage(named: "community-search-field-icon")?
        .withRenderingMode(.alwaysOriginal))
    let clearButton = UIButton(type: .system)
    let searchField = UITextField()
    let recentStack = UIStackView()
    let recentChips = UIStackView()
    let resultsStack = UIStackView()
    var recentQueries = ["기숙사", "동아리 면접", "포트폴리오"]
    var previousNavigationBarHidden = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        previousNavigationBarHidden = navigationController?.isNavigationBarHidden ?? false
        navigationController?.setNavigationBarHidden(true, animated: animated)
        DispatchQueue.main.async { [weak self] in self?.searchField.becomeFirstResponder() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(previousNavigationBarHidden, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 246 / 255, green: 249 / 255, blue: 252 / 255, alpha: 1)
        if let topConstraint = scrollView.constraints.first(where: {
            $0.firstItem === contentStack && $0.firstAttribute == .top
        }) {
            topConstraint.constant = 8
        }
        contentStack.spacing = 16
        configureSearchField()
        contentStack.addArrangedSubview(makeSearchBar())
        contentStack.addArrangedSubview(makeRecentSearches())

        resultsStack.axis = .vertical
        resultsStack.spacing = 10
        resultsStack.isHidden = true
        contentStack.addArrangedSubview(resultsStack)
    }

    private func configureSearchField() {
        searchField.placeholder = "제목·내용 검색"
        searchField.font = .systemFont(ofSize: 15)
        searchField.textColor = AppStyle.ink
        searchField.returnKeyType = .search
        searchField.clearButtonMode = .never
        searchField.delegate = self
        searchField.backgroundColor = .white
        searchField.layer.cornerRadius = 25
        searchField.layer.borderWidth = 1
        searchField.layer.borderColor = AppStyle.line.cgColor
        searchField.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255,
            alpha: 1).withAlphaComponent(0.05).cgColor
        searchField.layer.shadowOpacity = 1
        searchField.layer.shadowRadius = 12
        searchField.layer.shadowOffset = CGSize(width: 0, height: 4)
        searchField.heightAnchor.constraint(equalToConstant: 50).isActive = true

        searchFieldIcon.contentMode = .scaleAspectFit
        searchFieldIcon.frame = CGRect(x: 0, y: 0, width: 18, height: 18)
        let left = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 32))
        searchFieldIcon.center = CGPoint(x: 26, y: 16)
        left.addSubview(searchFieldIcon)
        searchField.leftView = left
        searchField.leftViewMode = .always

        clearButton.setImage(UIImage(named: "community-search-clear-icon")?.withRenderingMode(.alwaysOriginal),
            for: .normal)
        clearButton.accessibilityLabel = "검색어 지우기"
        clearButton.accessibilityIdentifier = "community-search-clear"
        clearButton.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        clearButton.isHidden = true
        clearButton.addAction(UIAction { [weak self] _ in self?.clearSearch() }, for: .touchUpInside)
        searchField.rightView = clearButton
        searchField.rightViewMode = .always
        searchField.addTarget(self, action: #selector(searchTextDidChange), for: .editingChanged)
    }

    private func makeSearchBar() -> UIStackView {
        let cancel = UIButton(type: .system)
        cancel.setTitle("취소", for: .normal)
        cancel.setTitleColor(AppStyle.blue, for: .normal)
        cancel.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        cancel.accessibilityIdentifier = "community-search-cancel"
        cancel.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)
        let row = UIStackView(arrangedSubviews: [searchField, cancel])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10
        cancel.setContentHuggingPriority(.required, for: .horizontal)
        return row
    }

    private func makeRecentSearches() -> UIStackView {
        let title = AppStyle.label("최근 검색어", size: 14, weight: .medium, color: AppStyle.muted)
        let clear = UIButton(type: .system)
        clear.setTitle("전체 삭제", for: .normal)
        clear.setTitleColor(AppStyle.muted, for: .normal)
        clear.titleLabel?.font = .systemFont(ofSize: 12)
        clear.addAction(UIAction { [weak self] _ in
            self?.recentQueries.removeAll()
            self?.renderRecentSearches()
        }, for: .touchUpInside)
        let header = UIStackView(arrangedSubviews: [title, UIView(), clear])
        header.axis = .horizontal
        header.alignment = .center

        recentChips.axis = .horizontal
        recentChips.spacing = 8
        recentChips.alignment = .leading
        recentStack.axis = .vertical
        recentStack.spacing = 12
        recentStack.addArrangedSubview(header)
        recentStack.addArrangedSubview(recentChips)
        renderRecentSearches()
        return recentStack
    }

}

@MainActor
extension CommunitySearchViewController {
    func renderRecentSearches() {
        recentChips.arrangedSubviews.forEach { view in
            recentChips.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        recentQueries.forEach { query in
            let chip = UIButton(type: .system)
            chip.setTitle(query, for: .normal)
            chip.setTitleColor(AppStyle.muted, for: .normal)
            chip.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            chip.backgroundColor = .white
            chip.layer.cornerRadius = 19
            chip.layer.borderWidth = 1
            chip.layer.borderColor = AppStyle.line.cgColor
            var configuration = UIButton.Configuration.plain()
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
            chip.configuration = configuration
            chip.addAction(UIAction { [weak self] _ in
                self?.searchField.text = query
                self?.runSearch()
            }, for: .touchUpInside)
            recentChips.addArrangedSubview(chip)
        }
    }

    func runSearch() {
        let query = searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !query.isEmpty else { return }
        if !recentQueries.contains(query) { recentQueries.insert(query, at: 0) }
        renderRecentSearches()
        recentStack.isHidden = true
        resultsStack.isHidden = false
        renderResults(for: query)
        view.endEditing(true)
        clearButton.isHidden = false
    }

    func renderResults(for query: String) {
        resultsStack.arrangedSubviews.forEach { view in
            resultsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        let normalizedQuery = query.lowercased()
        let posts = CommunityPostStore.shared.posts.filter { post in
            post.title.lowercased().contains(normalizedQuery) || post.body.lowercased().contains(normalizedQuery)
        }
        guard !posts.isEmpty else {
            resultsStack.addArrangedSubview(AppStyle.label("검색 결과 0개", size: 14, color: secondary))
            resultsStack.addArrangedSubview(makeEmptyState())
            return
        }
        resultsStack.addArrangedSubview(AppStyle.label("검색 결과 \(posts.count)개", size: 14, weight: .medium,
            color: secondary))
        posts.forEach { post in resultsStack.addArrangedSubview(makeResultCard(post)) }
    }

}

@MainActor
extension CommunitySearchViewController {
    func makeResultCard(_ post: CommunityPost) -> UIView {
        let content = makeResultCardContent(post)
        let card = makeResultCardContainer(content, post: post)
        return card
    }

    private func makeResultCardContent(_ post: CommunityPost) -> UIStackView {
        let badge = makeGradeBadge(post.grade)
        let title = makeResultTitle(post.title)
        let body = makeResultBody(post.body)
        let footer = makeResultFooter(post)
        let content = UIStackView(arrangedSubviews: [badge, title, body, footer])
        content.axis = .vertical
        content.spacing = 8
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        return content
    }

    private func makeGradeBadge(_ grade: String) -> UIView {
        let badge = UIView()
        badge.backgroundColor = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)
        badge.layer.cornerRadius = 12
        let badgeLabel = AppStyle.label(grade, size: 12, color: brandBlue)
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(badgeLabel)
        NSLayoutConstraint.activate([
            badgeLabel.topAnchor.constraint(equalTo: badge.topAnchor, constant: 4),
            badgeLabel.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 10),
            badgeLabel.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -10),
            badgeLabel.bottomAnchor.constraint(equalTo: badge.bottomAnchor, constant: -4),
            badge.heightAnchor.constraint(equalToConstant: 24),
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 39)
        ])
        return badge
    }

    private func makeResultTitle(_ text: String) -> UILabel {
        let title = AppStyle.label(text, size: 15, weight: .medium, color: AppStyle.ink)
        title.attributedText = NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 15, weight: .medium),
            .foregroundColor: AppStyle.ink,
            .paragraphStyle: lineStyle(height: 24)
        ])
        title.numberOfLines = 1
        return title
    }

    private func makeResultBody(_ text: String) -> UILabel {
        let body = AppStyle.label(text, size: 14, weight: .medium, color: secondary)
        body.attributedText = NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: secondary,
            .paragraphStyle: lineStyle(height: 20)
        ])
        body.numberOfLines = 2
        return body
    }

    private func makeResultFooter(_ post: CommunityPost) -> UIStackView {
        let footer = UIStackView(arrangedSubviews: [
            AppStyle.label("\(post.grade) · \(post.time)", size: 12, color: tertiary),
            UIView(),
            makeStat(icon: "community-search-heart-icon", count: post.likes),
            makeStat(icon: "community-search-comment-icon", count: post.comments)
        ])
        footer.axis = .horizontal
        footer.alignment = .center
        footer.spacing = 8
        return footer
    }

    private func makeResultCardContainer(_ content: UIView, post: CommunityPost) -> UIControl {
        let card = UIControl()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.borderWidth = 1
        card.layer.borderColor = AppStyle.line.cgColor
        card.layer.shadowColor = UIColor(
            red: 26 / 255,
            green: 64 / 255,
            blue: 128 / 255,
            alpha: 0.05
        ).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        card.accessibilityLabel = "\(post.title), 좋아요 \(post.likes), 댓글 \(post.comments)개"
        card.addAction(UIAction { [weak self] _ in
            self?.push(CommunityPostDetailViewController(post: post))
        }, for: .touchUpInside)
        return card
    }

    func lineStyle(height: CGFloat) -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = height
        style.maximumLineHeight = height
        return style
    }

    func makeStat(icon: String, count: Int) -> UIStackView {
        let image = UIImageView(image: UIImage(named: icon)?.withRenderingMode(.alwaysOriginal))
        image.contentMode = .scaleAspectFit
        image.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            image.widthAnchor.constraint(equalToConstant: 14),
            image.heightAnchor.constraint(equalToConstant: 14)
        ])
        let label = AppStyle.label("\(count)", size: 12, color: tertiary)
        let stat = UIStackView(arrangedSubviews: [image, label])
        stat.axis = .horizontal
        stat.alignment = .center
        stat.spacing = 4
        return stat
    }

    func clearSearch() {
        searchField.text = nil
        clearButton.isHidden = true
        recentStack.isHidden = false
        resultsStack.isHidden = true
        DispatchQueue.main.async { [weak self] in self?.searchField.becomeFirstResponder() }
    }

    @objc func searchTextDidChange() {
        clearButton.isHidden = (searchField.text ?? "").isEmpty
    }

}

@MainActor
extension CommunitySearchViewController {
    func makeEmptyState() -> UIView {
        let state = makeEmptyStateStack()
        let container = UIView()
        container.heightAnchor.constraint(
            equalTo: scrollView.frameLayoutGuide.heightAnchor,
            constant: -100
        ).isActive = true
        container.addSubview(state)
        state.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            state.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            state.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            state.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 12),
            state.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -12)
        ])
        return container
    }

    private func makeEmptyStateStack() -> UIStackView {
        let illustration = UIView()
        illustration.backgroundColor = .white
        illustration.layer.cornerRadius = 44
        illustration.layer.borderWidth = 1
        illustration.layer.borderColor = AppStyle.line.cgColor
        illustration.layer.shadowColor = UIColor(red: 0.10, green: 0.25, blue: 0.50, alpha: 1).cgColor
        illustration.layer.shadowOpacity = 0.10
        illustration.layer.shadowRadius = 14
        illustration.layer.shadowOffset = CGSize(width: 0, height: 6)
        illustration.widthAnchor.constraint(equalToConstant: 88).isActive = true
        illustration.heightAnchor.constraint(equalToConstant: 88).isActive = true

        let icon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        icon.tintColor = AppStyle.blue
        icon.contentMode = .scaleAspectFit
        illustration.addSubview(icon)
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: illustration.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: illustration.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 36),
            icon.heightAnchor.constraint(equalToConstant: 36)
        ])

        let title = AppStyle.label("검색 결과가 없어요", size: 18, weight: .semibold)
        title.textAlignment = .center
        let subtitle = AppStyle.label("다른 단어로 검색하거나 게시판을 바꿔 보세요.", size: 14, color: AppStyle.muted)
        subtitle.textAlignment = .center
        let state = UIStackView(arrangedSubviews: [illustration, title, subtitle])
        state.axis = .vertical
        state.alignment = .center
        state.spacing = 12

        return state
    }

}

@MainActor
extension CommunitySearchViewController {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        runSearch()
        return true
    }
}
