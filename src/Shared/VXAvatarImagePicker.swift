import AVFoundation
import Photos
import PhotosUI
import UIKit

final class VXImageSourcePicker: NSObject, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private weak var presenter: UIViewController?
    private let purpose: String
    private let didSelectImage: (UIImage) -> Void

    init(presenter: UIViewController, purpose: String = "choose a profile photo", didSelectImage: @escaping (UIImage) -> Void) {
        self.presenter = presenter
        self.purpose = purpose
        self.didSelectImage = didSelectImage
    }

    func presentSourceSheet() {
        let sheet = VXActionSheetViewController(actions: [
            VXSheetAction("Choose from Photos") { [weak self] in self?.requestPhotoLibrary() },
            VXSheetAction("Take Photo") { [weak self] in self?.requestCamera() }
        ])
        presenter?.present(sheet, animated: true)
    }

    private func requestPhotoLibrary() {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized, .limited:
            presentPhotoLibrary()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if status == .authorized || status == .limited {
                        self.presentPhotoLibrary()
                    } else {
                        self.showPermissionAlert(kind: "Photo Library")
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert(kind: "Photo Library")
        @unknown default:
            showPermissionAlert(kind: "Photo Library")
        }
    }

    private func presentPhotoLibrary() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        presenter?.present(picker, animated: true)
    }

    private func requestCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presenter?.vxAlert(title: "Camera Unavailable", message: "This device does not have an available camera.", actions: [("OK", .default, nil)])
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            presentCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    granted ? self.presentCamera() : self.showPermissionAlert(kind: "Camera")
                }
            }
        case .denied, .restricted:
            showPermissionAlert(kind: "Camera")
        @unknown default:
            showPermissionAlert(kind: "Camera")
        }
    }

    private func presentCamera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = self
        presenter?.present(picker, animated: true)
    }

    private func showPermissionAlert(kind: String) {
        presenter?.vxAlert(
            title: "\(kind) Access Required",
            message: "Allow \(kind.lowercased()) access in Settings to \(purpose).",
            actions: [
                ("Cancel", .cancel, nil),
                ("Open Settings", .default, {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                })
            ]
        )
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async { self?.didSelectImage(image) }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        guard let image = info[.originalImage] as? UIImage else {
            picker.dismiss(animated: true)
            return
        }
        picker.dismiss(animated: true) { [weak self] in self?.didSelectImage(image) }
    }
}
