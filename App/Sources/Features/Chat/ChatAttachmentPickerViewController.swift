import PhotosUI
import UIKit
import UniformTypeIdentifiers

@MainActor
final class ChatAttachmentPickerViewController: UIViewController, PHPickerViewControllerDelegate, UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var onAttachmentSelected: ((String, UIImage?) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(AppStyle.label("무엇을 첨부할까요?", size: 21, weight: .bold))
        stack.addArrangedSubview(AppStyle.label("사진이나 파일을 질문에 추가할 수 있어요", size: 14, color: AppStyle.muted))
        stack.addArrangedSubview(AppStyle.button("카메라로 촬영", action: { [weak self] in self?.openCamera() }))
        stack.addArrangedSubview(AppStyle.button("사진 보관함", action: { [weak self] in self?.openPhotoLibrary() }))
        stack.addArrangedSubview(AppStyle.button("파일 선택", action: { [weak self] in self?.openFiles() }))
        stack.addArrangedSubview(AppStyle.button("현재 위치", action: { [weak self] in
            self?.showMessage("위치 공유 화면은 별도 위치 화면 이슈에서 연결할게요")
        }))

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 22),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showMessage("이 기기에서는 카메라를 사용할 수 없어요")
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }

    private func openPhotoLibrary() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func openFiles() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.image, .pdf], asCopy: true)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let result = results.first else {
            dismiss(animated: true)
            return
        }
        let provider = result.itemProvider
        guard provider.canLoadObject(ofClass: UIImage.self) else {
            dismiss(animated: true)
            return
        }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            DispatchQueue.main.async {
                self?.finishSelection("사진", image: object as? UIImage)
            }
        }
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        finishSelection(url.lastPathComponent, image: nil)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        finishSelection("촬영한 사진", image: info[.originalImage] as? UIImage)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    private func finishSelection(_ name: String, image: UIImage?) {
        dismiss(animated: true) { [weak self] in
            self?.onAttachmentSelected?(name, image)
        }
    }

    private func showMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
