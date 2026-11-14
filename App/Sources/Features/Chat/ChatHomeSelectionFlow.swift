import UIKit

@MainActor
extension ChatHomeViewController {
    @objc func selectDepartment() {
        let picker = DepartmentPickerViewController(selectedDepartment: selectedDepartment)
        picker.onSelect = { [weak self] department in
            guard let self else { return }
            self.selectedDepartment = department
            UserDefaults.standard.set(department, forKey: "chat.selectedDepartment")
            self.updateContextChipTitles()
            self.updateRecommendationTitle()
        }
        present(picker, animated: true)
    }

    @objc func selectMajor() {
        let picker = MajorPickerViewController(selectedMajor: selectedMajor)
        picker.onComplete = { [weak self] major in
            guard let self else { return }
            self.selectedMajor = major ?? "전공 선택"
            UserDefaults.standard.set(major, forKey: "chat.selectedMajor")
            self.updateContextChipTitles()
            self.updateRecommendationTitle()
        }
        present(picker, animated: true)
    }

}
