import UIKit
import SnapKit
import AVFoundation

public final class SocialChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    public var onBack: (() -> Void)?
    public var onMore: ((SocialUser) -> Void)?
    public var onSendMessage: ((SocialMessage) -> Void)?
    public var onPlayVoice: ((SocialMessage) -> Void)?
    public var onRecordingPermissionDenied: (() -> Void)?
    public var onLocalError: ((String) -> Void)?
    public var onRetry: (() -> Void)?
    public var messageLoader: SocialDataLoader<[SocialMessage]>?
    public var onPersistMessage: ((SocialMessage, @escaping SocialMutationCompletion<SocialMessage>) -> Void)?
    public var onBlockedUserExit: ((SocialUser) -> Void)?

    private let participant: SocialUser
    private let currentUserID: String
    private var messages: [SocialMessage]
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let stateView = SocialStateView()
    private let inputBar = UIView()
    private let modeButton = UIButton(type: .system)
    private let textField = UITextField()
    private let imageButton = UIButton(type: .system)
    private let sendButton = UIButton(type: .system)
    private let holdButton = UIButton(type: .system)
    private let recordingModeButton = UIButton(type: .system)
    private var isVoiceMode = false
    private var audioRecorder: AVAudioRecorder?
    private var recordingStartedAt: Date?
    private var recordingShouldCancel = false
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    private var playingMessageID: String?
    private var playbackProgress: Double = 0
    private var blockObserver: NSObjectProtocol?
    private lazy var imagePicker = VXImageSourcePicker(presenter: self, purpose: "send a photo") { [weak self] image in
        self?.sendImage(image)
    }

    public init(participant: SocialUser, currentUserID: String, messages: [SocialMessage]) {
        self.participant = participant; self.currentUserID = currentUserID; self.messages = messages.sorted { $0.sentAt < $1.sentAt }
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad(); socialConfigureBase(); buildLayout(); observeBlocking()
        messageLoader == nil ? render() : reloadFromRepository()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isViewLoaded, messageLoader != nil { reloadFromRepository() }
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if navigationController?.topViewController !== self { stopPlayback(refresh: false) }
    }

    deinit {
        playbackTimer?.invalidate()
        if let blockObserver { NotificationCenter.default.removeObserver(blockObserver) }
    }

    public func reloadFromRepository() {
        guard let messageLoader else { render(); return }
        apply(state: .loading)
        messageLoader { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let items): self?.apply(state: items.isEmpty ? .empty(message: "Start the conversation") : .loaded(items))
                case .failure(let error): self?.apply(state: .failure(message: error.localizedDescription))
                }
            }
        }
    }

    public func apply(state: SocialLoadState<[SocialMessage]>) {
        guard isViewLoaded else { if case .loaded(let items) = state { messages = items }; return }
        tableView.isHidden = true; stateView.isHidden = false
        switch state {
        case .loading: stateView.showLoading()
        case .empty(let message): stateView.showMessage(message, retry: false)
        case .failure(let message): stateView.showMessage(message, retry: true)
        case .loaded(let items): messages = items.sorted { $0.sentAt < $1.sentAt }; render()
        }
    }

    private func buildLayout() {
        let back = SocialIconButton(systemName: "arrow.left", pointSize: 28); let more = SocialIconButton(systemName: "line.3.horizontal", pointSize: 25)
        let headerAvatar = SocialAvatarView(); headerAvatar.configure(user: participant)
        let title = UILabel(); title.text = "Posting as \(participant.role)"; title.font = .systemFont(ofSize: 14, weight: .semibold); title.textColor = SocialPalette.text
        let identity = UIStackView(arrangedSubviews: [headerAvatar, title]); identity.axis = .horizontal; identity.alignment = .center; identity.spacing = 8
        back.socialOnTap(self, #selector(backTapped)); more.socialOnTap(self, #selector(moreTapped))
        view.addSubview(back); view.addSubview(more); view.addSubview(identity); view.addSubview(tableView); view.addSubview(stateView); view.addSubview(inputBar)
        back.snp.makeConstraints { $0.leading.equalTo(18); $0.top.equalTo(view.safeAreaLayoutGuide).offset(12); $0.size.equalTo(44) }
        more.snp.makeConstraints { $0.trailing.equalTo(-17); $0.centerY.equalTo(back); $0.size.equalTo(44) }
        identity.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(back)
            $0.leading.greaterThanOrEqualTo(back.snp.trailing).offset(8)
            $0.trailing.lessThanOrEqualTo(more.snp.leading).offset(-8)
        }
        headerAvatar.snp.makeConstraints { $0.size.equalTo(26) }

        inputBar.backgroundColor = SocialPalette.softGreen; inputBar.layer.cornerRadius = 13
        [modeButton, imageButton, sendButton].forEach { $0.tintColor = UIColor(white: 0.17, alpha: 1); inputBar.addSubview($0) }
        inputBar.addSubview(textField); inputBar.addSubview(holdButton)
        modeButton.setImage(UIImage(systemName: "mic.fill"), for: .normal); imageButton.setImage(UIImage(systemName: "photo", withConfiguration: UIImage.SymbolConfiguration(pointSize: 21, weight: .medium)), for: .normal); sendButton.setImage(UIImage(systemName: "paperplane.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)), for: .normal)
        textField.placeholder = "Enter..."; textField.font = .systemFont(ofSize: 14); textField.returnKeyType = .send; textField.delegate = self
        holdButton.setTitle("Hold to Talk", for: .normal); holdButton.setTitleColor(SocialPalette.text, for: .normal); holdButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .regular); holdButton.isHidden = true
        recordingModeButton.setImage(UIImage(systemName: "circle.grid.3x3.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 19, weight: .bold)), for: .normal)
        recordingModeButton.tintColor = SocialPalette.text
        recordingModeButton.isHidden = true
        recordingModeButton.socialOnTap(self, #selector(modeTapped))
        inputBar.addSubview(recordingModeButton)
        modeButton.socialOnTap(self, #selector(modeTapped)); imageButton.socialOnTap(self, #selector(imageTapped)); sendButton.socialOnTap(self, #selector(sendTapped))
        let recordingGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleRecordingGesture(_:)))
        recordingGesture.minimumPressDuration = 0
        recordingGesture.allowableMovement = .greatestFiniteMagnitude
        holdButton.addGestureRecognizer(recordingGesture)
        modeButton.snp.makeConstraints { $0.leading.equalTo(8); $0.centerY.equalToSuperview(); $0.size.equalTo(36) }
        textField.snp.makeConstraints { $0.leading.equalTo(modeButton.snp.trailing).offset(2); $0.centerY.equalToSuperview(); $0.trailing.equalTo(imageButton.snp.leading).offset(-8); $0.height.equalTo(40) }
        imageButton.snp.makeConstraints { $0.trailing.equalTo(sendButton.snp.leading).offset(-6); $0.centerY.equalToSuperview(); $0.size.equalTo(36) }
        sendButton.snp.makeConstraints { $0.trailing.equalTo(-15); $0.centerY.equalToSuperview(); $0.size.equalTo(36) }
        holdButton.snp.makeConstraints { $0.edges.equalToSuperview() }
        recordingModeButton.snp.makeConstraints { $0.leading.equalTo(8); $0.centerY.equalToSuperview(); $0.size.equalTo(40) }
        inputBar.snp.makeConstraints {
            $0.leading.equalTo(15); $0.trailing.equalTo(-15); $0.height.equalTo(53)
            $0.bottom.equalTo(view.keyboardLayoutGuide.snp.top).offset(-8).priority(.high)
            $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(8)
        }

        tableView.backgroundColor = SocialPalette.page; tableView.separatorStyle = .none; tableView.showsVerticalScrollIndicator = false; tableView.keyboardDismissMode = .interactive; tableView.estimatedRowHeight = 90; tableView.rowHeight = UITableView.automaticDimension; tableView.dataSource = self; tableView.delegate = self; tableView.register(SocialMessageCell.self, forCellReuseIdentifier: "SocialMessageCell")
        tableView.snp.makeConstraints { $0.top.equalTo(back.snp.bottom).offset(13); $0.leading.trailing.equalToSuperview(); $0.bottom.equalTo(inputBar.snp.top).offset(-8) }
        stateView.snp.makeConstraints { $0.edges.equalTo(tableView) }
        stateView.actionButton.socialOnTap(self, #selector(retryTapped))
    }

    private func render() {
        tableView.reloadData(); tableView.isHidden = false; stateView.isHidden = true
        if messages.isEmpty { tableView.isHidden = true; stateView.isHidden = false; stateView.showMessage("Start the conversation", retry: false) }
        DispatchQueue.main.async { [weak self] in self?.scrollToLatest(animated: false) }
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messages.count }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SocialMessageCell", for: indexPath) as! SocialMessageCell
        let message = messages[indexPath.row]
        let progress = playingMessageID == message.id ? playbackProgress : nil
        cell.configure(message: message, fallbackAvatar: message.isFromCurrentUser ? nil : participant, playbackProgress: progress, isVoicePlaying: playingMessageID == message.id && audioPlayer?.isPlaying == true)
        cell.onVoice = { [weak self] in self?.toggleVoicePlayback(message) }
        return cell
    }
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let first = messages.first else { return nil }
        let label = UILabel(); let formatter = DateFormatter(); formatter.dateFormat = "a hh:mm"; label.text = formatter.string(from: first.sentAt); label.textAlignment = .center; label.textColor = SocialPalette.weak; label.font = .systemFont(ofSize: 16); return label
    }
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { messages.isEmpty ? 0 : 34 }
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool { sendText(); return false }

    private func submit(content: SocialMessageContent) {
        let message = SocialMessage(id: UUID().uuidString, senderID: currentUserID, isFromCurrentUser: true, sentAt: Date(), content: content)
        guard let onPersistMessage else { appendPersisted(message); return }
        setInputEnabled(false)
        onPersistMessage(message) { [weak self] result in
            DispatchQueue.main.async {
                self?.setInputEnabled(true)
                switch result {
                case .success(let persisted): self?.appendPersisted(persisted)
                case .failure(let error): self?.emitLocalError(error.localizedDescription)
                }
            }
        }
    }
    private func appendPersisted(_ message: SocialMessage) {
        messages.append(message); messages.sort { $0.sentAt < $1.sentAt }
        tableView.isHidden = false; stateView.isHidden = true; tableView.reloadData(); scrollToLatest(animated: true)
        onSendMessage?(message)
        NotificationCenter.default.post(name: .socialDataDidChange, object: self)
    }
    private func sendText() { guard let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }; submit(content: .text(text)); textField.text = nil }
    private func setInputEnabled(_ enabled: Bool) { [modeButton, imageButton, sendButton, holdButton, recordingModeButton].forEach { $0.isEnabled = enabled }; textField.isEnabled = enabled }
    private func scrollToLatest(animated: Bool) { guard !messages.isEmpty else { return }; tableView.scrollToRow(at: IndexPath(row: messages.count - 1, section: 0), at: .bottom, animated: animated) }

    @objc private func backTapped() { if let onBack { onBack() } else { navigationController?.popViewController(animated: true) } }
    @objc private func moreTapped() { onMore?(participant) }
    @objc private func retryTapped() { onRetry?(); reloadFromRepository() }
    @objc private func sendTapped() { sendText() }
    @objc private func modeTapped() {
        isVoiceMode.toggle(); textField.resignFirstResponder(); holdButton.isHidden = !isVoiceMode; recordingModeButton.isHidden = !isVoiceMode
        modeButton.isHidden = isVoiceMode; textField.isHidden = isVoiceMode; imageButton.isHidden = isVoiceMode; sendButton.isHidden = isVoiceMode
        inputBar.backgroundColor = isVoiceMode ? SocialPalette.brand : SocialPalette.softGreen
    }
    @objc private func imageTapped() {
        imagePicker.presentSourceSheet()
    }

    private func sendImage(_ image: UIImage) {
        do { submit(content: .image(try storeImage(image))) }
        catch { emitLocalError(error.localizedDescription) }
    }

    private func storeImage(_ image: UIImage) throws -> SocialImageAttachment {
        guard let data = image.jpegData(compressionQuality: 0.9) ?? image.pngData() else { throw SocialLocalError.invalidImage }
        let url = try attachmentURL(extension: "jpg")
        do { try data.write(to: url, options: .atomic) }
        catch { throw SocialLocalError.cannotStoreAttachment }
        return SocialImageAttachment(image: image, data: data, localURL: url)
    }

    @objc private func handleRecordingGesture(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            recordingShouldCancel = false
            requestRecordingPermissionAndStart()
        case .changed:
            recordingShouldCancel = gesture.location(in: holdButton).y < -44
            holdButton.setTitle(recordingShouldCancel ? "Release to Cancel" : "Release to Send", for: .normal)
        case .ended:
            finishRecording(cancel: recordingShouldCancel)
        case .cancelled, .failed:
            finishRecording(cancel: true)
        default: break
        }
    }
    private func requestRecordingPermissionAndStart() {
        let permission = AVAudioSession.sharedInstance().recordPermission
        switch permission {
        case .granted: startRecording()
        case .denied: emitRecordingPermissionDenied()
        case .undetermined: AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in DispatchQueue.main.async { granted ? self?.startRecording() : self?.emitRecordingPermissionDenied() } }
        @unknown default: emitRecordingPermissionDenied()
        }
    }
    private func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker]); try session.setActive(true)
            let url = try attachmentURL(extension: "m4a")
            let settings: [String: Any] = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 12_000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
            let recorder = try AVAudioRecorder(url: url, settings: settings); recorder.delegate = self
            guard recorder.prepareToRecord(), recorder.record() else { throw SocialLocalError.recordingFailed }
            audioRecorder = recorder; recordingStartedAt = Date(); holdButton.setTitle("Release to Send", for: .normal)
        } catch { emitLocalError(error.localizedDescription) }
    }
    private func finishRecording(cancel: Bool) {
        guard let recorder = audioRecorder, let startedAt = recordingStartedAt else { return }
        let duration = Date().timeIntervalSince(startedAt)
        if cancel { recorder.stop(); recorder.deleteRecording() } else { recorder.stop() }
        audioRecorder = nil; recordingStartedAt = nil; holdButton.setTitle("Hold to Talk", for: .normal)
        try? AVAudioSession.sharedInstance().setActive(false)
        guard !cancel else { return }
        guard duration >= 0.6 else { try? FileManager.default.removeItem(at: recorder.url); emitLocalError(SocialLocalError.recordingTooShort.localizedDescription); return }
        guard FileManager.default.fileExists(atPath: recorder.url.path) else { emitLocalError(SocialLocalError.recordingFailed.localizedDescription); return }
        submit(content: .voice(duration: duration, localURL: recorder.url))
    }

    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        audioRecorder = nil; recordingStartedAt = nil; try? FileManager.default.removeItem(at: recorder.url)
        emitLocalError(error?.localizedDescription ?? SocialLocalError.recordingFailed.localizedDescription)
    }

    private func attachmentURL(extension fileExtension: String) throws -> URL {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { throw SocialLocalError.cannotStoreAttachment }
        let directory = base.appendingPathComponent("Vixia/SocialAttachments", isDirectory: true)
        do { try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true) }
        catch { throw SocialLocalError.cannotStoreAttachment }
        return directory.appendingPathComponent(UUID().uuidString).appendingPathExtension(fileExtension)
    }

    private func emitRecordingPermissionDenied() {
        onRecordingPermissionDenied?()
        guard onRecordingPermissionDenied == nil else { return }
        let alert = VXAlertViewController(title: "Microphone Access Needed", message: "Enable microphone access in Settings to send voice messages.", actions: [
            ("Cancel", .cancel, nil),
            ("Open Settings", .default, {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
            })
        ])
        present(alert, animated: true)
    }

    private func emitLocalError(_ message: String) {
        onLocalError?(message)
        guard onLocalError == nil, presentedViewController == nil else { return }
        vxAlert(title: "Local Operation Failed", message: message, actions: [("OK", .default, nil)])
    }

    private func toggleVoicePlayback(_ message: SocialMessage) {
        onPlayVoice?(message)
        if playingMessageID == message.id, let audioPlayer {
            if audioPlayer.isPlaying {
                audioPlayer.pause()
                playbackTimer?.invalidate(); playbackTimer = nil
            } else {
                guard audioPlayer.play() else { emitLocalError(SocialLocalError.playbackFailed.localizedDescription); return }
                startPlaybackTimer()
            }
            refreshMessage(id: message.id)
            return
        }
        guard case .voice(_, let localURL) = message.content, FileManager.default.fileExists(atPath: localURL.path) else {
            emitLocalError(SocialLocalError.playbackFailed.localizedDescription); return
        }
        stopPlayback(refresh: true)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
            let player = try AVAudioPlayer(contentsOf: localURL)
            player.delegate = self; player.prepareToPlay()
            guard player.play() else { throw SocialLocalError.playbackFailed }
            audioPlayer = player; playingMessageID = message.id; playbackProgress = 0
            startPlaybackTimer()
            refreshMessage(id: message.id)
        } catch { emitLocalError(error.localizedDescription) }
    }

    private func startPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in self?.updatePlaybackProgress() }
    }

    private func updatePlaybackProgress() {
        guard let audioPlayer, audioPlayer.duration > 0, let playingMessageID else { return }
        playbackProgress = min(1, audioPlayer.currentTime / audioPlayer.duration)
        refreshMessage(id: playingMessageID)
    }

    private func stopPlayback(refresh: Bool) {
        let previousID = playingMessageID
        playbackTimer?.invalidate(); playbackTimer = nil
        audioPlayer?.stop(); audioPlayer = nil
        playingMessageID = nil; playbackProgress = 0
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        if refresh, let previousID { refreshMessage(id: previousID) }
    }

    private func refreshMessage(id: String) {
        guard let row = messages.firstIndex(where: { $0.id == id }), tableView.numberOfRows(inSection: 0) > row else { return }
        tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
    }

    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { stopPlayback(refresh: true) }
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        stopPlayback(refresh: true); emitLocalError(error?.localizedDescription ?? SocialLocalError.playbackFailed.localizedDescription)
    }

    private func observeBlocking() {
        blockObserver = NotificationCenter.default.addObserver(forName: .socialUserDidBlock, object: nil, queue: .main) { [weak self] notification in
            guard let self, notification.userInfo?[SocialNotificationKey.userID] as? String == self.participant.id else { return }
            self.stopPlayback(refresh: false)
            self.onBlockedUserExit?(self.participant)
            if self.navigationController?.topViewController === self { self.navigationController?.popViewController(animated: true) }
            else { self.dismiss(animated: true) }
        }
    }
}

private final class SocialMessageCell: UITableViewCell {
    var onVoice: (() -> Void)?
    private let avatar = SocialAvatarView(); private let bubble = UIView(); private let messageLabel = UILabel(); private let photo = UIImageView(); private let voiceButton = UIButton(type: .system); private let voiceProgress = UISlider(); private let voiceDuration = UILabel()
    private var leadingConstraint: Constraint?; private var trailingConstraint: Constraint?
    private var textConstraints: [Constraint] = []
    private var photoConstraints: [Constraint] = []
    private var voiceConstraints: [Constraint] = []
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier); backgroundColor = SocialPalette.page; selectionStyle = .none
        messageLabel.font = .systemFont(ofSize: 13); messageLabel.numberOfLines = 0; messageLabel.textColor = SocialPalette.text
        bubble.backgroundColor = SocialPalette.softGreen; bubble.layer.cornerRadius = 13; photo.contentMode = .scaleAspectFill; photo.clipsToBounds = true; photo.layer.cornerRadius = 13
        voiceButton.tintColor = SocialPalette.text; voiceButton.contentHorizontalAlignment = .left; voiceButton.socialOnTap(self, #selector(voiceTapped))
        voiceProgress.minimumValue = 0; voiceProgress.maximumValue = 1; voiceProgress.minimumTrackTintColor = SocialPalette.text; voiceProgress.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.72); voiceProgress.setThumbImage(Self.sliderThumb, for: .normal); voiceProgress.isUserInteractionEnabled = false
        voiceDuration.font = .systemFont(ofSize: 16, weight: .bold); voiceDuration.textColor = SocialPalette.text; voiceDuration.textAlignment = .right
        contentView.addSubview(avatar); contentView.addSubview(bubble); bubble.addSubview(messageLabel); bubble.addSubview(photo); bubble.addSubview(voiceButton); voiceButton.addSubview(voiceProgress); voiceButton.addSubview(voiceDuration)
        avatar.snp.makeConstraints { $0.top.equalTo(6); $0.bottom.lessThanOrEqualTo(-6); $0.size.equalTo(54); $0.leading.equalTo(15) }
        bubble.snp.makeConstraints { make in make.top.equalTo(6); make.bottom.equalTo(-6); make.width.lessThanOrEqualTo(contentView.snp.width).multipliedBy(0.72); leadingConstraint = make.leading.equalTo(avatar.snp.trailing).offset(10).constraint; trailingConstraint = make.trailing.equalTo(avatar.snp.leading).offset(-10).constraint }
        messageLabel.snp.makeConstraints { make in
            textConstraints = [make.top.equalTo(10).constraint, make.leading.equalTo(12).constraint, make.trailing.equalTo(-12).constraint, make.bottom.equalTo(-10).constraint, make.width.lessThanOrEqualTo(184).constraint]
        }
        photo.snp.makeConstraints { make in
            photoConstraints = [make.edges.equalToSuperview().constraint, make.width.equalTo(120).constraint, make.height.equalTo(192).constraint]
        }
        voiceButton.snp.makeConstraints { make in
            voiceConstraints = [make.top.equalTo(8).constraint, make.leading.equalTo(13).constraint, make.trailing.equalTo(-13).constraint, make.bottom.equalTo(-8).constraint, make.width.equalTo(152).constraint, make.height.equalTo(23).constraint]
        }
        voiceDuration.snp.makeConstraints { $0.trailing.equalToSuperview(); $0.centerY.equalToSuperview(); $0.width.equalTo(28) }
        voiceProgress.snp.makeConstraints { $0.leading.equalTo(31); $0.trailing.equalTo(voiceDuration.snp.leading).offset(-7); $0.centerY.equalToSuperview(); $0.height.equalTo(20) }
        trailingConstraint?.deactivate()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func prepareForReuse() { super.prepareForReuse(); onVoice = nil }
    func configure(message: SocialMessage, fallbackAvatar: SocialUser?, playbackProgress: Double?, isVoicePlaying: Bool) {
        messageLabel.isHidden = true; photo.isHidden = true; voiceButton.isHidden = true; voiceProgress.isHidden = true
        textConstraints.forEach { $0.deactivate() }; photoConstraints.forEach { $0.deactivate() }; voiceConstraints.forEach { $0.deactivate() }
        bubble.backgroundColor = SocialPalette.softGreen
        if let fallbackAvatar { avatar.configure(user: fallbackAvatar) } else { avatar.setImage(message.avatar, fallback: "Me") }
        leadingConstraint?.deactivate(); trailingConstraint?.deactivate()
        if message.isFromCurrentUser {
            avatar.snp.remakeConstraints { $0.top.equalTo(6); $0.bottom.lessThanOrEqualTo(-6); $0.trailing.equalTo(-15); $0.size.equalTo(54) }
            trailingConstraint?.activate()
        } else {
            avatar.snp.remakeConstraints { $0.top.equalTo(6); $0.bottom.lessThanOrEqualTo(-6); $0.leading.equalTo(15); $0.size.equalTo(54) }
            leadingConstraint?.activate()
        }
        switch message.content {
        case .text(let text): messageLabel.text = text; messageLabel.isHidden = false; textConstraints.forEach { $0.activate() }
        case .image(let attachment): photo.image = attachment.image; photo.isHidden = false; photoConstraints.forEach { $0.activate() }
        case .voice(let duration, _):
            voiceButton.setImage(UIImage(systemName: isVoicePlaying ? "pause.fill" : "play.fill"), for: .normal)
            voiceDuration.text = "\(Int(duration.rounded()))′"
            voiceProgress.value = Float(playbackProgress ?? 0); voiceProgress.isHidden = false; voiceDuration.isHidden = false
            voiceButton.isHidden = false; bubble.backgroundColor = SocialPalette.brand; voiceConstraints.forEach { $0.activate() }
        }
    }

    private static let sliderThumb: UIImage = {
        let size = CGSize(width: 14, height: 14)
        return UIGraphicsImageRenderer(size: size).image { _ in
            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()
        }
    }()
    @objc private func voiceTapped() { onVoice?() }
}
