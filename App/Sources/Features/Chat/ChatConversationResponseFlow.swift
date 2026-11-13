import UIKit
import Network

@MainActor
extension ChatConversationViewController {
    func observeNetworkStatus() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async { self?.updateNetworkStatus(isOffline: path.status != .satisfied) }
        }
        networkMonitor.start(queue: DispatchQueue(label: "kr.hs.gsm.hopes.chat-network"))
    }

    func updateNetworkStatus(isOffline: Bool) {
        guard self.isOffline != isOffline else { return }
        self.isOffline = isOffline
        if isOffline {
            showOfflineBanner()
            inputField.placeholder = "오프라인 상태예요"
            inputField.isEnabled = false
            if generationTimer != nil {
                generationTimer?.cancel()
                generationTimer = nil
                if let pendingAnswerCard {
                    messagesStack.removeArrangedSubview(pendingAnswerCard)
                    pendingAnswerCard.removeFromSuperview()
                    self.pendingAnswerCard = nil
                }
                stopAnswerButton.isHidden = true
                retryWhenOnline = true
                showPendingStatus()
            }
        } else {
            offlineBanner?.removeFromSuperview()
            offlineBanner = nil
            pendingStatusRow?.removeFromSuperview()
            pendingStatusRow = nil
            inputField.placeholder = "추가 질문 입력…"
            inputField.isEnabled = true
            if retryWhenOnline {
                retryWhenOnline = false
                beginAnswerGeneration()
            }
        }
    }

    func showOfflineBanner() {
        guard offlineBanner == nil else { return }
        let banner = UIStackView()
        banner.axis = .horizontal
        banner.alignment = .center
        banner.spacing = 8
        banner.isLayoutMarginsRelativeArrangement = true
        banner.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        banner.backgroundColor = AppStyle.ink
        banner.layer.cornerRadius = 14
        let icon = UIImageView(image: UIImage(systemName: "wifi.slash"))
        icon.tintColor = .white
        icon.widthAnchor.constraint(equalToConstant: 18).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 18).isActive = true
        let message = AppStyle.label("인터넷 연결이 끊겼어요. 연결되면 자동으로 다시 시도해요.", size: 12, color: .white)
        banner.addArrangedSubview(icon)
        banner.addArrangedSubview(message)
        messagesStack.insertArrangedSubview(banner, at: min(1, messagesStack.arrangedSubviews.count))
        offlineBanner = banner
    }

    func showPendingStatus() {
        guard pendingStatusRow == nil else { return }
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 6
        let clock = UIImageView(image: UIImage(systemName: "clock"))
        clock.tintColor = AppStyle.muted
        clock.widthAnchor.constraint(equalToConstant: 14).isActive = true
        clock.heightAnchor.constraint(equalToConstant: 14).isActive = true
        row.addArrangedSubview(UIView())
        row.addArrangedSubview(clock)
        row.addArrangedSubview(AppStyle.label("연결되면 전송돼요", size: 12, color: AppStyle.muted))
        messagesStack.addArrangedSubview(row)
        pendingStatusRow = row
    }

    func beginAnswerGeneration() {
        if isOffline {
            retryWhenOnline = true
            showPendingStatus()
            return
        }
        let card = AppStyle.card()
        card.layer.cornerRadius = 24
        card.layer.shadowColor = AppStyle.blue.withAlphaComponent(0.08).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 14
        card.layer.shadowOffset = CGSize(width: 0, height: 6)

        let title = AppStyle.label("Frontend 시작 순서", size: 18, weight: .semibold)
        let partial = AppStyle.label("처음에는 화면을 직접 만들어 보는 것부터 시작하는 걸 추천해요. HTML·CSS로 간단한 페이지를", size: 15)
        let cursor = UIView()
        cursor.backgroundColor = AppStyle.blue
        cursor.widthAnchor.constraint(equalToConstant: 2).isActive = true
        cursor.heightAnchor.constraint(equalToConstant: 18).isActive = true
        let content = UIStackView(arrangedSubviews: [title, partial, cursor])
        content.axis = .vertical
        content.spacing = 10
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        messagesStack.addArrangedSubview(card)
        pendingAnswerCard = card
        stopAnswerButton.isHidden = false
        inputField.placeholder = "답변을 만드는 중이에요…"
        inputField.isEnabled = false

        let work = DispatchWorkItem { [weak self] in self?.finishAnswerGeneration() }
        generationTimer = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: work)
    }

    func finishAnswerGeneration() {
        generationTimer = nil
        if let pendingAnswerCard {
            messagesStack.removeArrangedSubview(pendingAnswerCard)
            pendingAnswerCard.removeFromSuperview()
            self.pendingAnswerCard = nil
        }
        stopAnswerButton.isHidden = true
        inputField.isEnabled = true
        inputField.placeholder = "추가 질문 입력…"
        addFormattedAnswer()
    }

    func stopAnswerGeneration() {
        generationTimer?.cancel()
        generationTimer = nil
        stopAnswerButton.isHidden = true
        inputField.isEnabled = true
        inputField.placeholder = "추가 질문 입력…"
        if let pendingAnswerCard {
            messagesStack.removeArrangedSubview(pendingAnswerCard)
            pendingAnswerCard.removeFromSuperview()
            self.pendingAnswerCard = nil
        }
        addAnswerFailure()
    }

}
