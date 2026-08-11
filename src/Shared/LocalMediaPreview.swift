import UIKit
import AVFoundation
import AVKit
import SnapKit

enum LocalMediaPreview {
    private static let cache = NSCache<NSString, UIImage>()

    static func thumbnail(for reference: LocalMediaReference, completion: @escaping (UIImage?) -> Void) {
        let key = reference.localIdentifier as NSString
        if let cached = cache.object(forKey: key) {
            completion(cached)
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let image = makeThumbnail(for: reference)
            if let image { cache.setObject(image, forKey: key) }
            DispatchQueue.main.async { completion(image) }
        }
    }

    static func makeThumbnail(for reference: LocalMediaReference) -> UIImage? {
        switch reference.kind {
        case .image:
            return UIImage(named: reference.localIdentifier) ?? UIImage(contentsOfFile: reference.localIdentifier)
        case .video:
            guard let url = resolvedVideoURL(for: reference.localIdentifier) else { return nil }
            let asset = AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 1200, height: 1200)
            guard let image = try? generator.copyCGImage(at: CMTime(seconds: 0, preferredTimescale: 600), actualTime: nil) else { return nil }
            return UIImage(cgImage: image)
        }
    }

    static func resolvedVideoURL(for identifier: String) -> URL? {
        if FileManager.default.fileExists(atPath: identifier) { return URL(fileURLWithPath: identifier) }
        let source = identifier as NSString
        let name = source.deletingPathExtension
        let ext = source.pathExtension.isEmpty ? "mp4" : source.pathExtension
        return Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "video")
            ?? Bundle.main.url(forResource: name, withExtension: ext)
    }
}

final class LocalMediaFullscreenViewController: UIViewController {
    private let reference: LocalMediaReference

    init(reference: LocalMediaReference) {
        self.reference = reference
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 19, weight: .bold)), for: .normal)
        close.tintColor = .white
        close.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        close.layer.cornerRadius = 22
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(close)
        close.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.size.equalTo(44)
        }

        switch reference.kind {
        case .image:
            let imageView = UIImageView(image: UIImage(named: reference.localIdentifier) ?? UIImage(contentsOfFile: reference.localIdentifier))
            imageView.contentMode = .scaleAspectFit
            view.insertSubview(imageView, belowSubview: close)
            imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        case .video:
            guard let url = LocalMediaPreview.resolvedVideoURL(for: reference.localIdentifier) else { return }
            let player = AVPlayer(url: url)
            let playerController = AVPlayerViewController()
            playerController.player = player
            addChild(playerController)
            view.insertSubview(playerController.view, belowSubview: close)
            playerController.view.snp.makeConstraints { $0.edges.equalToSuperview() }
            playerController.didMove(toParent: self)
            player.play()
        }
    }

    @objc private func closeTapped() { dismiss(animated: true) }
}
