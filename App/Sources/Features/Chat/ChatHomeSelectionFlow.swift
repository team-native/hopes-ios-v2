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
        let picker = MajorPickerViewController(selectedMajor: selectedMajor)
        picker.onComplete = { [weak self] major in
            guard let self else { return }
            let didChange = self.selectedMajor != major
            self.selectedMajor = major
            UserDefaults.standard.set(major ?? "", forKey: "chat.selectedMajor")
            self.applyContextSelection(didChange: didChange)
        }
        present(picker, animated: false)
    }

    @objc func retryRecommendations() {
        loadRecommendations()
    }

    func loadRecommendations() {
        recommendationRequestID += 1
        let requestID = recommendationRequestID
        questionSetIndex = 0
        guard selectedDepartment != nil, selectedMajor != nil else {
            updateRecommendationTitle()
            return
        }
        recommendationState = .loading
        updateRecommendationTitle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self, self.recommendationRequestID == requestID,
                  self.recommendationState == .loading else { return }
            self.recommendationState = .ready
            self.updateRecommendationTitle()
        }
    }

    private func applyContextSelection(didChange: Bool) {
        updateContextChipTitles()
        if didChange, selectedDepartment != nil, selectedMajor != nil {
            loadRecommendations()
        }
    }
}
