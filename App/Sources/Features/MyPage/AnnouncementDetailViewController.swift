import UIKit

@MainActor
final class AnnouncementDetailViewController: AppPageViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = nil
        hidesBottomBarWhenPushed = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        contentStack.spacing = 16
        addHeader()
        addAnnouncementCard()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func addHeader() {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = AppStyle.ink
        backButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)

        let title = AppStyle.label("공지", size: 18, weight: .medium)
        let subtitle = AppStyle.label("시스템 공지", size: 12, color: AppStyle.muted)
        let labels = UIStackView(arrangedSubviews: [title, subtitle])
        labels.axis = .vertical

        let header = UIStackView(arrangedSubviews: [backButton, labels])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 12
        contentStack.addArrangedSubview(header)
    }

    private func addAnnouncementCard() {
        let card = AppStyle.card()
        card.layer.cornerRadius = 24

        let badgeLabel = AppStyle.label("시스템 공지", size: 12, color: AppStyle.blue)
        let badge = UIView()
        badge.backgroundColor = AppStyle.paleBlue
        badge.layer.cornerRadius = 14
        badge.addSubview(badgeLabel)
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            badgeLabel.topAnchor.constraint(equalTo: badge.topAnchor, constant: 4),
            badgeLabel.bottomAnchor.constraint(equalTo: badge.bottomAnchor, constant: -4),
            badgeLabel.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 10),
            badgeLabel.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -10)
        ])
        badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 78).isActive = true

        let title = AppStyle.label("답변 데이터 업데이트 완료", size: 22, weight: .bold)
        title.numberOfLines = 0
        let date = AppStyle.label("2026.11.12", size: 12, color: AppStyle.muted)

        let divider = UIView()
        divider.backgroundColor = AppStyle.line
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true

        let body = UILabel()
        body.numberOfLines = 0
        body.attributedText = announcementBody()

        let content = UIStackView(arrangedSubviews: [badge, title, date, divider, body])
        content.axis = .vertical
        content.alignment = .leading
        content.spacing = 10
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            divider.widthAnchor.constraint(equalTo: content.widthAnchor)
        ])
        contentStack.addArrangedSubview(card)
    }

    private func announcementBody() -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4
        let text = "선배 답변 데이터가 업데이트됐어요. 학과·전공별 추천 질문이 더 정확해지고, "
            + "기숙사·입학 관련 답변이 최신 내용으로 바뀌었어요.\n\n"
            + "이용 중 불편한 점은 마이페이지 > 문의하기로 알려 주세요."
        return NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: 15),
                .foregroundColor: AppStyle.ink,
                .paragraphStyle: paragraph
            ]
        )
    }
}
