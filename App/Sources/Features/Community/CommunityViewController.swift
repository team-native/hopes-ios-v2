import UIKit

struct CommunityPost {
    let grade: String
    let title: String
    let body: String
    let detailBody: String?
    let time: String
    let comments: Int
    let likes: Int
    let category: String

    init(
        grade: String,
        title: String,
        body: String,
        time: String,
        comments: Int,
        likes: Int,
        category: String,
        detailBody: String? = nil
    ) {
        self.grade = grade
        self.title = title
        self.body = body
        self.detailBody = detailBody
        self.time = time
        self.comments = comments
        self.likes = likes
        self.category = category
    }
}

@MainActor
final class CommunityViewController: AppPageViewController {
    let brandBlue = UIColor(red: 47 / 255, green: 134 / 255, blue: 245 / 255, alpha: 1)
    let softBlue = UIColor(red: 230 / 255, green: 241 / 255, blue: 254 / 255, alpha: 1)
    let line = UIColor(red: 235 / 255, green: 241 / 255, blue: 250 / 255, alpha: 1)
    let defaultBorder = UIColor(red: 220 / 255, green: 230 / 255, blue: 244 / 255, alpha: 1)
    let ink = UIColor(red: 20 / 255, green: 27 / 255, blue: 43 / 255, alpha: 1)
    let canvas = UIColor(red: 246 / 255, green: 249 / 255, blue: 252 / 255, alpha: 1)
    let secondary = UIColor(red: 107 / 255, green: 120 / 255, blue: 144 / 255, alpha: 1)
    let tertiary = UIColor(red: 152 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
    let postStack = UIStackView()
    var selectedBoard = "전체"
    var boardFilters: UIStackView?
    var publishToast: UIView?
    var showingLoadError = ProcessInfo.processInfo.arguments.contains("--community-load-error")

    override func viewDidLoad() {
        super.viewDidLoad()
        title = nil
        view.backgroundColor = canvas
        contentStack.spacing = 16
        if let topConstraint = scrollView.constraints.first(where: {
            $0.firstItem === contentStack && $0.firstAttribute == .top
        }) {
            topConstraint.constant = 8
        }

        addHeader()
        addBoardFilters()

        postStack.axis = .vertical
        postStack.spacing = 10
        contentStack.addArrangedSubview(postStack)
        addWriteButton()
        renderPosts()
        view.accessibilityIdentifier = "community-home-screen"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        if isViewLoaded {
            renderPosts()
            if CommunityPostStore.shared.consumePublishedToast() { showPublishToast() }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    func addHeader() {
        let title = AppStyle.label("커뮤니티", size: 28, weight: .bold, color: ink)
        title.attributedText = NSAttributedString(string: "커뮤니티", attributes: [
            .font: UIFont.systemFont(ofSize: 28, weight: .bold),
            .foregroundColor: ink,
            .kern: -0.4
        ])
        title.heightAnchor.constraint(equalToConstant: 38).isActive = true
        title.numberOfLines = 1
        title.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let search = makeHeaderButton(asset: "community-search-icon", identifier: "community-search", label: "게시글 검색")
        search.addAction(UIAction { [weak self] _ in
            self?.push(CommunitySearchViewController())
        }, for: .touchUpInside)
        let profile = makeHeaderButton(asset: "community-profile-icon", identifier: "community-my-activity",
            label: "내 활동")
        profile.addAction(UIAction { [weak self] _ in
            self?.push(MyActivityViewController())
        }, for: .touchUpInside)

        let header = UIStackView(arrangedSubviews: [title, search, profile])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8
        contentStack.addArrangedSubview(header)
    }

    func makeHeaderButton(
        asset: String,
        identifier: String,
        label: String
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: asset)?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.backgroundColor = .white
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = line.cgColor
        button.layer.shadowColor = UIColor(red: 26 / 255, green: 64 / 255, blue: 128 / 255,
            alpha: 1).withAlphaComponent(0.05).cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 4
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.accessibilityIdentifier = identifier
        button.accessibilityLabel = label
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
        return button
    }

    func addBoardFilters() {
        let filters = UIStackView()
        filters.axis = .horizontal
        filters.alignment = .center
        filters.spacing = 8
        for board in ["전체", "8기", "9기", "10기", "11기"] {
            filters.addArrangedSubview(makeBoardFilter(board))
        }
        filters.addArrangedSubview(UIView())
        boardFilters = filters
        contentStack.addArrangedSubview(filters)
        selectFilterAppearance()
    }

    private func makeBoardFilter(_ board: String) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        var configuration = UIButton.Configuration.plain()
        configuration.title = board
        configuration.baseForegroundColor = secondary
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 14, weight: .medium)
            return outgoing
        }
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        button.configuration = configuration
        button.heightAnchor.constraint(equalToConstant: 38).isActive = true
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1
        button.accessibilityIdentifier = "community-board-\(board)"
        button.addAction(UIAction { [weak self] _ in self?.selectBoard(board) }, for: .touchUpInside)
        return button
    }

    func addWriteButton() {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "community-write-icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.backgroundColor = brandBlue
        button.layer.cornerRadius = 28
        button.layer.shadowColor = brandBlue.withAlphaComponent(0.28).cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 12
        button.layer.shadowOffset = CGSize(width: 0, height: 8)
        button.accessibilityIdentifier = "community-write-post"
        button.accessibilityLabel = "글 작성하기"
        button.addAction(UIAction { [weak self] _ in
            self?.push(CommunityWriteViewController())
        }, for: .touchUpInside)
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 56),
            button.heightAnchor.constraint(equalToConstant: 56),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30)
        ])
    }

}

@MainActor
extension CommunityViewController {
}

@MainActor
extension CommunityViewController {
    func showPublishToast() {
        publishToast?.removeFromSuperview()

        let checkCircle = UIView()
        checkCircle.backgroundColor = AppStyle.blue
        checkCircle.layer.cornerRadius = 11
        checkCircle.widthAnchor.constraint(equalToConstant: 22).isActive = true
        checkCircle.heightAnchor.constraint(equalToConstant: 22).isActive = true
        let checkmark = UIImageView(image: UIImage(systemName: "checkmark"))
        checkmark.tintColor = .white
        checkmark.contentMode = .scaleAspectFit
        checkCircle.addSubview(checkmark)
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            checkmark.centerXAnchor.constraint(equalTo: checkCircle.centerXAnchor),
            checkmark.centerYAnchor.constraint(equalTo: checkCircle.centerYAnchor),
            checkmark.widthAnchor.constraint(equalToConstant: 12),
            checkmark.heightAnchor.constraint(equalToConstant: 12)
        ])

        let message = AppStyle.label("게시글을 등록했어요", size: 14, color: .white)
        let toast = UIStackView(arrangedSubviews: [checkCircle, message])
        toast.axis = .horizontal
        toast.alignment = .center
        toast.spacing = 10
        toast.isLayoutMarginsRelativeArrangement = true
        toast.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        toast.backgroundColor = AppStyle.ink
        toast.layer.cornerRadius = 26
        toast.layer.shadowColor = UIColor.black.cgColor
        toast.layer.shadowOpacity = 0.18
        toast.layer.shadowRadius = 12
        toast.layer.shadowOffset = CGSize(width: 0, height: 5)
        toast.isUserInteractionEnabled = false
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        presentToast(toast)
    }

    private func presentToast(_ toast: UIStackView) {
        publishToast = toast
        toast.alpha = 0
        toast.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        UIView.animate(withDuration: 0.2) {
            toast.alpha = 1
            toast.transform = .identity
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self, weak toast] in
            guard let self, let toast, self.publishToast === toast else { return }
            UIView.animate(withDuration: 0.2, animations: {
                toast.alpha = 0
                toast.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            }, completion: { _ in
                toast.removeFromSuperview()
                self.publishToast = nil
            })
        }
    }

    func selectBoard(_ board: String) {
        selectedBoard = board
        selectFilterAppearance()
        renderPosts()
    }

    func renderPosts() {
        postStack.arrangedSubviews.forEach { view in
            postStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        if showingLoadError {
            postStack.addArrangedSubview(makeLoadErrorState())
            selectFilterAppearance()
            return
        }
        let visiblePosts = CommunityPostStore.shared.posts.filter { selectedBoard == "전체" || $0.grade == selectedBoard }
        if visiblePosts.isEmpty {
            postStack.addArrangedSubview(makeEmptyState())
        } else {
            visiblePosts.forEach { post in postStack.addArrangedSubview(makePostCard(post)) }
        }
        selectFilterAppearance()
    }

    func showLoadError() {
        showingLoadError = true
        renderPosts()
    }

}
