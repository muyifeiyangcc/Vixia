import UIKit
import PhotosUI
import UniformTypeIdentifiers
import SnapKit

final class PublishViewController: VXScrollViewController, PHPickerViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private enum PickerMode { case photos, video }
    private struct MediaItem {
        let reference: LocalMediaReference
        let thumbnail: UIImage
    }

    private let mediaContainer = UIView()
    private let emptyMediaView = UIView()
    private lazy var mediaCollection = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let scooter = VXField(label: "Scooter (Required)", placeholder: "Classic Scooter 300cc (2023)", labelSize: 16, fieldHeight: 52)
    private let route = VXField(label: "Route & Distance (Required)", placeholder: "Malibu Coast Line & 42 mi", labelSize: 16, fieldHeight: 52)
    private let descriptionField = VXField(label: "Description", placeholder: "Tell riders about this Wave Drop", labelSize: 16, fieldHeight: 52)
    private let details = [
        VXField(label: "Exhaust", placeholder: "Sport Exhaust System", labelSize: 16, fieldHeight: 52),
        VXField(label: "Suspension", placeholder: "Sport Gas Rear Shocks", labelSize: 16, fieldHeight: 52),
        VXField(label: "Seat", placeholder: "Leather Diamond Stitch", labelSize: 16, fieldHeight: 52),
        VXField(label: "Wheels", placeholder: "Lightweight Alloy 12\"", labelSize: 16, fieldHeight: 52),
        VXField(label: "ECU", placeholder: "Sport ECU Tuner", labelSize: 16, fieldHeight: 52),
        VXField(label: "Lighting", placeholder: "LED Headlight", labelSize: 16, fieldHeight: 52)
    ]
    private let submit = UIButton(type: .system)
    private let balanceButton = UIButton(type: .system)
    private var pickerMode: PickerMode = .photos
    private var mediaItems: [MediaItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        contentStack.spacing = 17

        let header = makeHeader()
        configureMediaModule()
        configureSubmitButton()
        [header, mediaContainer, scooter, route, descriptionField].forEach(contentStack.addArrangedSubview)
        details.forEach(contentStack.addArrangedSubview)
        contentStack.setCustomSpacing(21, after: header)
        contentStack.setCustomSpacing(24, after: mediaContainer)

        header.snp.makeConstraints { $0.height.equalTo(44) }
        mediaContainer.snp.makeConstraints { $0.height.equalTo(244) }
        view.addSubview(submit)
        submit.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(37)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(8)
            make.height.equalTo(60)
        }
        scrollView.contentInset.bottom = 84
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateBalance()
    }

    private func makeHeader() -> UIView {
        let header = UIView()
        let title = vxLabel("Wave Drop", size: 36, weight: .heavy)
        balanceButton.setTitleColor(VXColor.ink, for: .normal)
        balanceButton.titleLabel?.font = VXFont.body(18, weight: .bold)
        balanceButton.setImage(UIImage(named: "diamond")?.withRenderingMode(.alwaysOriginal), for: .normal)
        balanceButton.backgroundColor = VXColor.lime
        balanceButton.layer.borderWidth = 1
        balanceButton.layer.borderColor = VXColor.deepLime.cgColor
        balanceButton.layer.cornerRadius = 17
        balanceButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 12)
        balanceButton.imageEdgeInsets = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 7)
        balanceButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        balanceButton.addTarget(self, action: #selector(openRecharge), for: .touchUpInside)
        updateBalance()
        header.addSubview(title)
        header.addSubview(balanceButton)
        title.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(balanceButton.snp.leading).offset(-12)
        }
        balanceButton.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(90)
            make.height.equalTo(34)
        }
        return header
    }

    private func updateBalance() {
        balanceButton.setTitle(LocalStore.shared.diamondBalance.formatted(), for: .normal)
    }

    @objc private func openRecharge() {
        navigationController?.pushViewController(RechargeViewController(), animated: true)
    }

    private func configureMediaModule() {
        mediaContainer.backgroundColor = UIColor(hex: 0xF1F3EC)
        mediaContainer.layer.cornerRadius = 16
        mediaContainer.layer.borderWidth = 1
        mediaContainer.layer.borderColor = VXColor.deepLime.cgColor
        mediaContainer.clipsToBounds = true

        let plus = vxLabel("+", size: 34, weight: .light)
        plus.textAlignment = .center
        let title = vxLabel("Add photos or video", size: 14, weight: .semibold)
        title.textAlignment = .center
        let subtitle = vxLabel("Up to 9 photos or one video", size: 12, color: VXColor.textSecondary)
        subtitle.textAlignment = .center
        let stack = UIStackView(arrangedSubviews: [plus, title, subtitle])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 7
        let emptyButton = UIButton(type: .custom)
        emptyButton.addTarget(self, action: #selector(showMediaSheet), for: .touchUpInside)
        emptyMediaView.addSubview(stack)
        emptyMediaView.addSubview(emptyButton)
        stack.snp.makeConstraints { $0.center.equalToSuperview() }
        emptyButton.snp.makeConstraints { $0.edges.equalToSuperview() }

        let layout = mediaCollection.collectionViewLayout as! UICollectionViewFlowLayout
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        mediaCollection.backgroundColor = .clear
        mediaCollection.showsHorizontalScrollIndicator = false
        mediaCollection.contentInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        mediaCollection.dataSource = self
        mediaCollection.delegate = self
        mediaCollection.register(PublishMediaCell.self, forCellWithReuseIdentifier: "media")
        mediaCollection.register(PublishAddMediaCell.self, forCellWithReuseIdentifier: "add")

        mediaContainer.addSubview(emptyMediaView)
        mediaContainer.addSubview(mediaCollection)
        emptyMediaView.snp.makeConstraints { $0.edges.equalToSuperview() }
        mediaCollection.snp.makeConstraints { $0.edges.equalToSuperview() }
        updateMediaModule()
    }

    private func configureSubmitButton() {
        submit.setTitle("DROP INTO WAVE", for: .normal)
        submit.setTitleColor(.white, for: .normal)
        submit.titleLabel?.font = VXFont.body(18, weight: .bold)
        submit.backgroundColor = .black
        submit.layer.cornerRadius = 30
        submit.addTarget(self, action: #selector(submitPost), for: .touchUpInside)
    }

    private func updateMediaModule() {
        emptyMediaView.isHidden = !mediaItems.isEmpty
        mediaCollection.isHidden = mediaItems.isEmpty
        mediaCollection.reloadData()
    }

    @objc private func showMediaSheet() {
        let sheet = VXActionSheetViewController(actions: [
            VXSheetAction("Choose Photos") { [weak self] in self?.presentPhotoPicker() },
            VXSheetAction("Choose Video") { [weak self] in self?.presentVideoPicker() }
        ])
        present(sheet, animated: true)
    }

    private func presentPhotoPicker() {
        let existingPhotos = mediaItems.filter { $0.reference.kind == .image }.count
        guard existingPhotos < 9 || mediaItems.contains(where: { $0.reference.kind == .video }) else {
            vxAlert(title: "Photo Limit Reached", message: "You can add up to 9 photos.", actions: [("OK", .default, nil)])
            return
        }
        pickerMode = .photos
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = mediaItems.contains(where: { $0.reference.kind == .video }) ? 9 : 9 - existingPhotos
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentVideoPicker() {
        pickerMode = .video
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 1
        configuration.filter = .videos
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else { return }
        switch pickerMode {
        case .photos: importPhotos(results)
        case .video: importVideo(results[0])
        }
    }

    private func importPhotos(_ results: [PHPickerResult]) {
        let replacesVideo = mediaItems.contains { $0.reference.kind == .video }
        let group = DispatchGroup()
        let lock = NSLock()
        var imported: [(Int, MediaItem)] = []
        results.enumerated().forEach { index, result in
            guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else { return }
            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                defer { group.leave() }
                guard let self, let image = object as? UIImage,
                      let item = self.persistImage(image) else { return }
                lock.lock(); imported.append((index, item)); lock.unlock()
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            let ordered = imported.sorted(by: { $0.0 < $1.0 }).map { $0.1 }
            if replacesVideo { self.mediaItems = ordered }
            else { self.mediaItems.append(contentsOf: ordered.prefix(max(0, 9 - self.mediaItems.count))) }
            self.updateMediaModule()
        }
    }

    private func importVideo(_ result: PHPickerResult) {
        let provider = result.itemProvider
        guard provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) else { return }
        provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] sourceURL, _ in
            guard let self, let sourceURL,
                  let destination = self.persistVideo(from: sourceURL) else { return }
            let reference = LocalMediaReference(id: UUID(), kind: .video, localIdentifier: destination.path)
            guard let thumbnail = LocalMediaPreview.makeThumbnail(for: reference) else { return }
            DispatchQueue.main.async {
                self.mediaItems = [MediaItem(reference: reference, thumbnail: thumbnail)]
                self.updateMediaModule()
            }
        }
    }

    private func persistImage(_ image: UIImage) -> MediaItem? {
        guard let data = image.jpegData(compressionQuality: 0.88),
              let directory = try? mediaDirectory() else { return nil }
        let url = directory.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
        do {
            try data.write(to: url, options: .atomic)
            let reference = LocalMediaReference(id: UUID(), kind: .image, localIdentifier: url.path)
            return MediaItem(reference: reference, thumbnail: image)
        } catch { return nil }
    }

    private func persistVideo(from sourceURL: URL) -> URL? {
        guard let directory = try? mediaDirectory() else { return nil }
        let fileExtension = sourceURL.pathExtension.isEmpty ? "mov" : sourceURL.pathExtension
        let destination = directory.appendingPathComponent(UUID().uuidString).appendingPathExtension(fileExtension)
        do {
            try FileManager.default.copyItem(at: sourceURL, to: destination)
            return destination
        } catch { return nil }
    }

    private func mediaDirectory() throws -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = base.appendingPathComponent("VixiaMedia", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mediaItems.count + 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == mediaItems.count {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "add", for: indexPath)
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "media", for: indexPath) as! PublishMediaCell
        let item = mediaItems[indexPath.item]
        cell.render(image: item.thumbnail, isVideo: item.reference.kind == .video)
        cell.onDelete = { [weak self] in
            guard let self, let index = self.mediaItems.firstIndex(where: { $0.reference.id == item.reference.id }) else { return }
            self.mediaItems.remove(at: index)
            self.updateMediaModule()
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < mediaItems.count else { showMediaSheet(); return }
        present(LocalMediaFullscreenViewController(reference: mediaItems[indexPath.item].reference), animated: true)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: indexPath.item == mediaItems.count ? 92 : 150, height: 220)
    }

    @objc private func submitPost() {
        if let tab = tabBarController as? MainTabController, tab.isGuest { tab.onGuestRestriction?(); return }
        guard !mediaItems.isEmpty,
              !(scooter.field.text ?? "").trimmingCharacters(in: .whitespaces).isEmpty,
              !(route.field.text ?? "").trimmingCharacters(in: .whitespaces).isEmpty else {
            vxAlert(title: "Complete your Wave Drop", message: "Add media, Scooter, and Route & Distance.", actions: [("OK", .default, nil)])
            return
        }
        submit.isEnabled = false
        let scooterText = (scooter.field.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let routeText = (route.field.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let routeParts = routeText.components(separatedBy: "&").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let specKeys = ["EXHAUST", "SUSPENSION", "SEAT", "WHEELS", "ECU", "LIGHTING"]
        var specs: [String: String] = [:]
        for (key, field) in zip(specKeys, details) {
            let value = (field.field.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !value.isEmpty { specs[key] = value }
        }
        let draft = RepositoryPostDraft(
            authorID: MockDataRepository.shared.currentUser.id,
            title: scooterText,
            route: routeParts.first ?? routeText,
            distance: routeParts.count > 1 ? routeParts.dropFirst().joined(separator: " & ") : "",
            body: (descriptionField.field.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            specs: specs,
            unlockPrice: 300,
            media: mediaItems.map(\.reference),
            routeNodes: []
        )
        _ = MockDataRepository.shared.createPost(draft)
        vxAlert(title: "Dropped into Wave", message: "Your post was saved.", actions: [("OK", .default, { [weak self] in
            guard let self else { return }
            self.submit.isEnabled = true
            self.mediaItems.removeAll()
            self.updateMediaModule()
            self.scooter.field.text = nil
            self.route.field.text = nil
            self.descriptionField.field.text = nil
            self.details.forEach { $0.field.text = nil }
            self.tabBarController?.selectedIndex = 0
        })])
    }
}

private final class PublishMediaCell: UICollectionViewCell {
    var onDelete: (() -> Void)?
    private let imageView = UIImageView()
    private let playIcon = UIImageView(image: UIImage(systemName: "play.fill"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = VXColor.softGreen
        layer.cornerRadius = 12
        clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        playIcon.tintColor = .white
        playIcon.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        playIcon.contentMode = .center
        playIcon.layer.cornerRadius = 22
        let delete = UIButton(type: .system)
        delete.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)), for: .normal)
        delete.tintColor = .white
        delete.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        delete.layer.cornerRadius = 13
        delete.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        contentView.addSubview(imageView)
        contentView.addSubview(playIcon)
        contentView.addSubview(delete)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        playIcon.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(44) }
        delete.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(7)
            make.size.equalTo(26)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func render(image: UIImage, isVideo: Bool) {
        imageView.image = image
        playIcon.isHidden = !isVideo
    }

    @objc private func deleteTapped() { onDelete?() }
}

private final class PublishAddMediaCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white.withAlphaComponent(0.72)
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = VXColor.deepLime.cgColor
        let plus = vxLabel("+", size: 32, weight: .light)
        plus.textAlignment = .center
        let text = vxLabel("Add", size: 13, weight: .semibold)
        text.textAlignment = .center
        let stack = UIStackView(arrangedSubviews: [plus, text])
        stack.axis = .vertical
        stack.spacing = 5
        contentView.addSubview(stack)
        stack.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }
}
