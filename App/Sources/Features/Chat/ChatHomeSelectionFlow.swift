import UIKit

@MainActor
extension ChatHomeViewController {
    @objc func selectDepartment() {
        let picker = DepartmentPickerViewController(selectedDepartment: selectedDepartment)
        picker.onComplete = { [weak self] department in
            guard let self else { return }
            let didChange = self.selectedDepartment != department
            self.selectedDepartment = department
            UserDefaults.standard.set(department ?? "", forKey: "chat.selectedDepartment")
            self.applyContextSelection(didChange: didChange)
        }
        present(picker, animated: false)
    }

    @objc func selectMajor() {
        let picker = MajorPickerViewController(selectedMajors: selectedMajors)
        picker.onComplete = { [weak self] majors in
            guard let self else { return }
            let didChange = self.selectedMajors != majors
            self.selectedMajors = majors
            ChatMajorSelection.save(majors)
            self.applyContextSelection(didChange: didChange)
        }
        present(picker, animated: false)
    }

    @objc func refreshQuestions() {
        guard recommendationState != .loading else { return }
        if recommendationState == .failed {
            retryRecommendations()
            return
        }
        if AccessTokenStore.shared.hasToken {
            loadRecommendations(refresh: true)
            return
        }
        questionSetIndex = (questionSetIndex + 1) % questionSets.count
        renderQuestions()
    }

    @objc func retryRecommendations() {
        loadRecommendations()
    }

    func loadRecommendations(refresh: Bool = false) {
        recommendationRequestID += 1
        let requestID = recommendationRequestID
        questionSetIndex = 0
        guard selectedDepartment != nil, selectedMajor != nil else {
            updateRecommendationTitle()
            return
        }
        recommendationState = .loading
        updateRecommendationTitle()
        if AccessTokenStore.shared.hasToken {
            loadServerRecommendations(requestID: requestID, refresh: refresh)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self, self.recommendationRequestID == requestID,
                  self.recommendationState == .loading else { return }
            self.recommendationState = .ready
            self.updateRecommendationTitle()
        }
    }

    private func loadServerRecommendations(requestID: Int, refresh: Bool) {
        let icons = ["chat-question-bed-icon", "chat-question-file-icon", "chat-question-code-icon",
                     "chat-question-heart-icon"]
        Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await CatalogAPI.recommendations(
                    department: self.selectedDepartment,
                    specialties: self.selectedMajors,
                    refreshToken: refresh ? self.recommendationRefreshToken : nil,
                    excludeIDs: refresh ? self.shownRecommendationIDs : []
                )
                guard self.recommendationRequestID == requestID else { return }
                self.recommendationRefreshToken = result.nextRefreshToken
                self.shownRecommendationIDs = result.items.map(\.id)
                if !result.items.isEmpty {
                    self.questionSets = [result.items.indices.map { index in
                        (icons[index % icons.count], result.items[index].content)
                    }]
                }
                self.recommendationState = .ready
            } catch {
                guard self.recommendationRequestID == requestID else { return }
                self.recommendationState = .failed
            }
            self.updateRecommendationTitle()
        }
    }

    private func applyContextSelection(didChange: Bool) {
        if didChange {
            let department = selectedDepartment
            let specialties = selectedMajors
            Task { await CatalogAPI.savePreferences(department: department, specialties: specialties) }
        }
        updateContextChipTitles()
        if didChange, !AccessTokenStore.shared.hasToken {
            questionSets = Self.defaultQuestionSets(major: selectedMajors.first)
        }
        if didChange, selectedDepartment != nil, selectedMajor != nil {
            loadRecommendations()
        }
    }
}
