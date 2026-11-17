import AVFoundation
import PhotosUI
import UIKit
import UniformTypeIdentifiers

@MainActor
final class ChatAttachmentPickerViewController: UIViewController, PHPickerViewControllerDelegate,
    UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var onAttachmentsSelected: (([ChatAttachmentItem]) -> Void)?

    private let dimView = UIView()
    private let sheetView = UIView()
    private var sheetBottomConstraint: NSLayoutConstraint?

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        modalPresentationStyle = .overFullScreen
        isModalInPresentation = true
        configureDimView()
        configureSheet()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sheetBottomConstraint?.constant = 0
        UIView.animate(withDuration: 0.32, delay: 0, usingSpringWithDamping: 0.88, initialSpringVelocity: 0.2) {
            self.dimView.alpha = 1
            self.view.layoutIfNeeded()
        }
    }

    @objc private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showMessage("이 기기에서는 카메라를 사용할 수 없어요")
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            presentCameraPicker()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] isAuthorized in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if isAuthorized {
                        self.presentCameraPicker()
                    } else {
                        self.showCameraPermissionAlert()
                    }
                }
            }
        case .denied, .restricted:
            showCameraPermissionAlert()
        @unknown default:
            showCameraPermissionAlert()
        }
    }

    private func presentCameraPicker() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }

    private func showCameraPermissionAlert() {
        let alert = UIAlertController(
            title: "사진 접근 권한이 필요해요",
            message: "사진을 첨부하려면 설정에서 hopes의 사진·카메라 접근을 허용해 주세요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "설정 열기", style: .default) { _ in
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(settingsURL)
        })
        present(alert, animated: true)
    }

    @objc private func openPhotoLibrary() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 3
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func openFiles() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard !results.isEmpty else {
            picker.dismiss(animated: true)
            return
        }
        let group = DispatchGroup()
        let lock = NSLock()
        var attachments = [ChatAttachmentItem?](repeating: nil, count: results.count)
        for (index, result) in results.enumerated() {
            let provider = result.itemProvider
            guard provider.canLoadObject(ofClass: UIImage.self) else { continue }
            let fileName = provider.suggestedName ?? "사진 \(index + 1)"
            group.enter()
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                let image = object as? UIImage
                let validationState = Self.imageValidationState(image)
                lock.lock()
                attachments[index] = ChatAttachmentItem(
                    fileName: fileName,
                    image: image,
                    validationState: validationState
                )
                lock.unlock()
                group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in
            let loadedAttachments = attachments.compactMap { $0 }
            guard loadedAttachments.count == results.count else {
                picker.dismiss(animated: true) {
                    self?.showMessage("선택한 사진을 불러오지 못했어요. 다시 선택해 주세요.")
                }
                return
            }
            self?.finishSelection(loadedAttachments)
        }
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard !urls.isEmpty else { return }
        controller.dismiss(animated: true) { [weak self] in
            Task { [weak self] in
                let documents = await Task.detached(priority: .userInitiated) {
                    urls.map(validateChatDocument(at:))
                }.value
                guard let self else { return }
                let attachments = documents.map {
                    ChatAttachmentItem(
                        fileName: $0.fileName,
                        image: nil,
                        url: $0.url,
                        validationState: $0.state,
                        pageCount: $0.pageCount
                    )
                }
                self.onAttachmentsSelected?(attachments)
            }
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let image = info[.originalImage] as? UIImage
        finishSelection([ChatAttachmentItem(
            fileName: "촬영한 사진", image: image, validationState: Self.imageValidationState(image)
        )])
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    private func finishSelection(_ attachments: [ChatAttachmentItem]) {
        dismiss(animated: true) { [weak self] in
            self?.onAttachmentsSelected?(attachments)
        }
    }

    private func showMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

@MainActor
private extension ChatAttachmentPickerViewController {
    func configureDimView() {
        dimView.backgroundColor = UIColor(red: 20 / 255.0, green: 28 / 255.0, blue: 43 / 255.0, alpha: 0.32)
        dimView.alpha = 0
        dimView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimView)
        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissSheet))
        dimView.addGestureRecognizer(dismissTap)
    }

    func configureSheet() {
        sheetView.backgroundColor = .white
        sheetView.layer.cornerRadius = 28
        sheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheetView.clipsToBounds = true
        sheetView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sheetView)

        let handle = makeSheetHandle()
        let content = makeSheetContent(handle: handle)
        sheetView.addSubview(content)
        let bottomConstraint = sheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 440)
        sheetBottomConstraint = bottomConstraint
        NSLayoutConstraint.activate([
            sheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomConstraint,
            content.topAnchor.constraint(equalTo: sheetView.topAnchor),
            content.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: sheetView.bottomAnchor),
            handle.widthAnchor.constraint(equalToConstant: 44),
            handle.heightAnchor.constraint(equalToConstant: 5)
        ])
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleSheetPan(_:)))
        sheetView.addGestureRecognizer(pan)
    }

    func makeSheetHandle() -> UIView {
        let handle = UIView()
        handle.backgroundColor = UIColor(red: 220 / 255.0, green: 230 / 255.0, blue: 244 / 255.0, alpha: 1)
        handle.layer.cornerRadius = 2.5
        handle.translatesAutoresizingMaskIntoConstraints = false
        return handle
    }

    func makeSheetContent(handle: UIView) -> UIStackView {
        let title = AppStyle.label("자료 첨부", size: 22, weight: .bold, color: ChatDetailPalette.ink)
        let footer = AppStyle.label(
            "이미지와 PDF를 첨부해서 질문할 수 있어요.",
            size: 12,
            color: ChatDetailPalette.placeholder
        )
        let handleContainer = UIView()
        handleContainer.addSubview(handle)
        NSLayoutConstraint.activate([
            handle.topAnchor.constraint(equalTo: handleContainer.topAnchor),
            handle.bottomAnchor.constraint(equalTo: handleContainer.bottomAnchor),
            handle.centerXAnchor.constraint(equalTo: handleContainer.centerXAnchor)
        ])
        let content = UIStackView(arrangedSubviews: [handleContainer, title, makeOptionRows(), footer])
        content.axis = .vertical
        content.spacing = 16
        content.isLayoutMarginsRelativeArrangement = true
        content.insetsLayoutMarginsFromSafeArea = false
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 38, trailing: 20)
        content.translatesAutoresizingMaskIntoConstraints = false
        return content
    }

    func makeOptionRows() -> UIStackView {
        let rows = UIStackView(arrangedSubviews: [
            makeOptionRow(title: "사진 보관함", subtitle: "이미지를 여러 장 선택할 수 있어요",
                iconName: "ChatAttachmentPhoto",
                action: #selector(openPhotoLibrary)),
            makeDivider(),
            makeOptionRow(title: "카메라 촬영", subtitle: "지금 찍어서 바로 질문해요",
                iconName: "ChatAttachmentCamera",
                action: #selector(openCamera)),
            makeDivider(),
            makeOptionRow(title: "파일에서 PDF 선택", subtitle: "PDF 문서를 첨부해요",
                iconName: "ChatAttachmentFile",
                action: #selector(openFiles))
        ])
        rows.axis = .vertical
        rows.spacing = 0
        return rows
    }

    func makeOptionRow(title: String, subtitle: String, iconName: String, action: Selector) -> UIView {
        let button = UIButton(type: .system)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.accessibilityLabel = "\(title), \(subtitle)"
        button.heightAnchor.constraint(equalToConstant: 68).isActive = true
        let chip = makeOptionIconChip(imageName: iconName)
        let heading = AppStyle.label(title, size: 15, weight: .medium, color: ChatDetailPalette.ink)
        let detail = AppStyle.label(subtitle, size: 12, color: ChatDetailPalette.muted)
        let labels = UIStackView(arrangedSubviews: [heading, detail])
        labels.axis = .vertical
        labels.spacing = 2
        let chevron = UIImageView(image: UIImage(named: "ChatAttachmentChevron")?.withRenderingMode(.alwaysOriginal))
        chevron.contentMode = .scaleAspectFit
        chevron.widthAnchor.constraint(equalToConstant: 18).isActive = true
        chevron.heightAnchor.constraint(equalToConstant: 18).isActive = true

        let row = UIStackView(arrangedSubviews: [chip, labels, chevron])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.isUserInteractionEnabled = false
        row.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            row.topAnchor.constraint(equalTo: button.topAnchor),
            row.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])
        return button
    }

    func makeOptionIconChip(imageName: String) -> UIView {
        let chip = UIView()
        chip.backgroundColor = ChatDetailPalette.brandSoft
        chip.layer.cornerRadius = 12
        chip.translatesAutoresizingMaskIntoConstraints = false
        let icon = UIImageView(image: UIImage(named: imageName)?.withRenderingMode(.alwaysOriginal))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        chip.addSubview(icon)
        NSLayoutConstraint.activate([
            chip.widthAnchor.constraint(equalToConstant: 44),
            chip.heightAnchor.constraint(equalToConstant: 44),
            icon.centerXAnchor.constraint(equalTo: chip.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: chip.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 22),
            icon.heightAnchor.constraint(equalToConstant: 22)
        ])
        return chip
    }

    func makeDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = ChatDetailPalette.border
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return divider
    }

    @objc func dismissSheet() {
        sheetBottomConstraint?.constant = 440
        UIView.animate(withDuration: 0.24, animations: {
            self.dimView.alpha = 0
            self.view.layoutIfNeeded()
        }, completion: { _ in self.dismiss(animated: false) })
    }

    @objc func handleSheetPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        switch gesture.state {
        case .changed where translation.y > 0:
            sheetBottomConstraint?.constant = translation.y
            dimView.alpha = max(0, 1 - translation.y / 440)
        case .ended:
            if translation.y > 100 {
                dismissSheet()
            } else {
                sheetBottomConstraint?.constant = 0
                UIView.animate(withDuration: 0.22) {
                    self.dimView.alpha = 1
                    self.view.layoutIfNeeded()
                }
            }
        default:
            break
        }
    }
}
