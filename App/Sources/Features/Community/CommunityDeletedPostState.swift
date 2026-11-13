import UIKit

@MainActor
extension CommunityPostDetailViewController {
    func showDeletedPostState() {
        let state = makeDeletedPostStack()
        let message = state.arrangedSubviews[2]
        let container = makeDeletedPostContainer(state: state, message: message)
        contentStack.addArrangedSubview(container)
    }

    private func makeDeletedPostStack() -> UIStackView {
        let circle = UIView()
        circle.backgroundColor = .white
        circle.layer.cornerRadius = 44
        circle.layer.shadowColor = UIColor(red: 0.10, green: 0.25, blue: 0.50, alpha: 1).cgColor
        circle.layer.shadowOpacity = 0.10
        circle.layer.shadowRadius = 14
        circle.layer.shadowOffset = CGSize(width: 0, height: 6)
        circle.widthAnchor.constraint(equalToConstant: 88).isActive = true
        circle.heightAnchor.constraint(equalToConstant: 88).isActive = true

        let trash = UIImageView(image: UIImage(systemName: "trash"))
        trash.tintColor = AppStyle.blue
        trash.contentMode = .scaleAspectFit
        circle.addSubview(trash)
        trash.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            trash.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            trash.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
            trash.widthAnchor.constraint(equalToConstant: 36),
            trash.heightAnchor.constraint(equalToConstant: 36)
        ])

        let heading = AppStyle.label("삭제된 게시글이에요", size: 18, weight: .semibold)
        heading.textAlignment = .center
        let message = AppStyle.label("작성자가 삭제했거나 운영 정책에 따라 숨겨진 글이에요.", size: 14, color: AppStyle.muted)
        message.textAlignment = .center

        let listButton = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = "목록으로"
        configuration.baseBackgroundColor = AppStyle.blue
        configuration.baseForegroundColor = .white
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        listButton.configuration = configuration
        listButton.layer.cornerRadius = 10
        listButton.clipsToBounds = true
        listButton.heightAnchor.constraint(equalToConstant: 36).isActive = true
        listButton.addAction(UIAction { [weak self] _ in self?.returnToCommunityList() }, for: .touchUpInside)

        let state = UIStackView(arrangedSubviews: [circle, heading, message, listButton])
        state.axis = .vertical
        state.alignment = .center
        state.spacing = 12
        return state
    }

    private func makeDeletedPostContainer(state: UIStackView, message: UIView) -> UIView {
        let container = UIView()
        container.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor,
            constant: -40).isActive = true
        container.addSubview(state)
        state.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            state.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            state.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            message.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 12),
            message.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -12)
        ])
        return container
    }

    func returnToCommunityList() {
        if let tabBarController,
           let viewControllers = tabBarController.viewControllers,
           viewControllers.indices.contains(2),
           let communityNavigation = viewControllers[2] as? UINavigationController {
            tabBarController.selectedViewController = communityNavigation
            communityNavigation.popToRootViewController(animated: true)
        } else if let navigationController {
            navigationController.popToRootViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

}
