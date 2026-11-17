import UIKit

@MainActor
extension ChatHomeViewController {
    func updateContextChipTitles() {
        var departmentConfiguration = departmentChip.configuration
        departmentConfiguration?.title = selectedDepartment.map { "학과 · \($0)" } ?? "학과 선택"
        departmentConfiguration?.baseForegroundColor = selectedDepartment == nil ? secondary : brandBlue
        departmentConfiguration?.background.backgroundColor = selectedDepartment == nil ? .white : softBlue
        departmentConfiguration?.background.strokeColor = selectedDepartment == nil ? line :
            UIColor(red: 169 / 255, green: 205 / 255, blue: 251 / 255, alpha: 1)
        departmentChip.configuration = departmentConfiguration

        var majorConfiguration = majorChip.configuration
        majorConfiguration?.title = selectedMajor.map { "전공 · \($0)" } ?? "전공 선택"
        majorConfiguration?.baseForegroundColor = selectedMajor == nil ? secondary : brandBlue
        majorConfiguration?.background.backgroundColor = selectedMajor == nil ? .white : softBlue
        majorConfiguration?.background.strokeColor = selectedMajor == nil ? line :
            UIColor(red: 169 / 255, green: 205 / 255, blue: 251 / 255, alpha: 1)
        majorChip.configuration = majorConfiguration
        updateRecommendationTitle()
    }

    func addInfoBanner() {
        infoBanner.translatesAutoresizingMaskIntoConstraints = false
        infoBanner.backgroundColor = softBlue
        infoBanner.layer.cornerRadius = 16
        let icon = UIImageView(image: UIImage(named: "chat-notice-alert")?.withRenderingMode(.alwaysOriginal))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        let message = UILabel()
        message.text = "학과와 전공을 고르면 나에게 맞는 질문을 추천해 드려요."
        message.font = .systemFont(ofSize: 12)
        message.textColor = brandBlue
        message.numberOfLines = 0
        let row = UIStackView(arrangedSubviews: [icon, message])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        row.translatesAutoresizingMaskIntoConstraints = false
        infoBanner.addSubview(row)
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18),
            row.topAnchor.constraint(equalTo: infoBanner.topAnchor),
            row.leadingAnchor.constraint(equalTo: infoBanner.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: infoBanner.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: infoBanner.bottomAnchor),
            infoBanner.heightAnchor.constraint(equalToConstant: 42)
        ])
        contentStack.addArrangedSubview(infoBanner)
        infoBanner.isHidden = true
    }

    func configureRecommendationFailureNotice() {
        recommendationFailureNotice.translatesAutoresizingMaskIntoConstraints = false
        recommendationFailureNotice.backgroundColor = softBlue
        recommendationFailureNotice.layer.cornerRadius = 16

        let icon = UIImageView(image: UIImage(named: "chat-notice-alert")?.withRenderingMode(.alwaysOriginal))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let message = UILabel()
        message.text = "맞춤 추천을 불러오지 못했어요.\n기본 질문을 보여드려요."
        message.font = .systemFont(ofSize: 12)
        message.textColor = secondary
        message.numberOfLines = 2
        message.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let retry = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = "다시 시도"
        configuration.baseForegroundColor = brandBlue
        configuration.baseBackgroundColor = softBlue
        configuration.background.cornerRadius = 10
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 14, weight: .medium)
            return outgoing
        }
        retry.configuration = configuration
        retry.accessibilityIdentifier = "chat-retry-recommendations"
        retry.addTarget(self, action: #selector(retryRecommendations), for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [icon, message, retry])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        row.translatesAutoresizingMaskIntoConstraints = false
        recommendationFailureNotice.addSubview(row)
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18),
            retry.widthAnchor.constraint(equalToConstant: 84),
            retry.heightAnchor.constraint(equalToConstant: 36),
            row.leadingAnchor.constraint(equalTo: recommendationFailureNotice.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: recommendationFailureNotice.trailingAnchor, constant: -12),
            row.centerYAnchor.constraint(equalTo: recommendationFailureNotice.centerYAnchor),
            recommendationFailureNotice.heightAnchor.constraint(equalToConstant: 60)
        ])
        recommendationFailureNotice.accessibilityIdentifier = "chat-recommendation-failure"
        contentStack.addArrangedSubview(recommendationFailureNotice)
        recommendationFailureNotice.isHidden = true
    }

    func addPromptTitle() {
        let title = "무엇이 궁금한가요?"
        let attributed = NSMutableAttributedString(string: title, attributes: [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: ink,
            .kern: -0.3
        ])
        if let range = title.range(of: "궁금한") {
            attributed.addAttribute(.foregroundColor, value: brandBlue, range: NSRange(range, in: title))
        }
        let label = UILabel()
        label.attributedText = attributed
        label.textAlignment = .center
        label.numberOfLines = 1

        let wrapper = UIView()
        label.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -6)
        ])
        promptTitleView = wrapper
        contentStack.addArrangedSubview(wrapper)
    }

    func updateRecommendationTitle() {
        let hasPersonalizedContext = selectedDepartment != nil && selectedMajor != nil
        if hasPersonalizedContext, let selectedDepartment, let selectedMajor {
            switch recommendationState {
            case .ready:
                recommendationTitleLabel?.text = "\(selectedDepartment) · \(selectedMajor) 추천 질문"
            case .loading:
                recommendationTitleLabel?.text = "\(selectedDepartment) · \(selectedMajor) 추천 질문 불러오는 중…"
            case .failed:
                recommendationTitleLabel?.text = "기본 추천 질문"
            }
        } else {
            recommendationState = .ready
            recommendationTitleLabel?.text = "기본 추천 질문"
        }
        renderQuestions()
    }

    static func loadContextValue(key: String, defaultValue: String) -> String? {
        guard let storedValue = UserDefaults.standard.string(forKey: key) else { return defaultValue }
        return storedValue.isEmpty ? nil : storedValue
    }
}
