import UIKit
import SnapKit

final class PostDetailViewController: VXScrollViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private var post: WavePost
    private let repository: VixiaRepository
    private var unlocked: Bool { post.authorID == repository.currentUser.id || LocalStore.shared.unlockedPostIDs.contains(post.id) }

    private let detailsStack = UIStackView()
    private let commentsStack = UIStackView()
    private let commentField = UITextField()
    private let likeCountLabel = vxLabel("", size: 14, weight: .medium)
    private let commentCountLabel = vxLabel("", size: 14, weight: .medium)
    private lazy var mediaCollection = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let mediaPageControl = UIPageControl()

    init(post: WavePost, repository: VixiaRepository = MockDataRepository.shared) {
        self.post = post
        self.repository = repository
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)

        let header = makeHeader()
        view.addSubview(header)
        header.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(44)
        }
        scrollView.snp.remakeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        contentStack.spacing = 12
        contentStack.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(20)
        }

        let title = vxLabel(post.title, size: 24, weight: .bold, lines: 2)
        let route = makeRouteSummary()
        let media = makeMediaCarousel()
        let bodyText = post.body.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = vxLabel(bodyText, size: 14, lines: 0)

        detailsStack.axis = .vertical
        detailsStack.spacing = 16

        let commentTitle = vxLabel("Comment", size: 22, weight: .bold)
        if let italic = commentTitle.font.fontDescriptor.withSymbolicTraits([.traitBold, .traitItalic]) {
            commentTitle.font = UIFont(descriptor: italic, size: 22)
        }
        commentsStack.axis = .vertical
        commentsStack.spacing = 18

        [title, route, media].forEach(contentStack.addArrangedSubview)
        if !bodyText.isEmpty {
            contentStack.addArrangedSubview(body)
        }
        [detailsStack, commentTitle, commentsStack].forEach(contentStack.addArrangedSubview)
        contentStack.setCustomSpacing(4, after: title)
        contentStack.setCustomSpacing(16, after: route)
        contentStack.setCustomSpacing(14, after: media)
        if !bodyText.isEmpty {
            contentStack.setCustomSpacing(15, after: body)
        }
        contentStack.setCustomSpacing(18, after: detailsStack)
        contentStack.setCustomSpacing(14, after: commentTitle)
        media.snp.makeConstraints { $0.height.equalTo(media.snp.width).multipliedBy(0.55) }
        commentTitle.snp.makeConstraints { $0.height.greaterThanOrEqualTo(27) }

        installInputBar()
        renderPanel()
        renderComments()
        updateCounts()
        NotificationCenter.default.addObserver(self, selector: #selector(repositoryDidChange(_:)), name: .vixiaRepositoryDidChange, object: nil)
    }

    @objc private func repositoryDidChange(_ notification: Notification) {
        let rawChange = notification.userInfo?[VixiaRepositoryNotificationKey.change] as? String
        guard rawChange == VixiaRepositoryChange.posts.rawValue || rawChange == VixiaRepositoryChange.blacklist.rawValue else { return }
        guard let updated = repository.post(post.id) else {
            navigationController?.popViewController(animated: true)
            return
        }
        post = updated
        renderComments()
        updateCounts()
    }

    private func makeHeader() -> UIView {
        let header = UIView()
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "arrow.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 27, weight: .bold)), for: .normal)
        backButton.tintColor = VXColor.ink
        backButton.addTarget(self, action: #selector(back), for: .touchUpInside)

        let rider = repository.user(post.authorID)
        let avatar = UIImageView(image: rider?.displayAvatarImage ?? UIImage(systemName: "person.crop.circle.fill"))
        avatar.tintColor = VXColor.textSecondary
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 13
        let identity = vxLabel("Posting as \(rider?.role.rawValue ?? "Rider")", size: 14, weight: .semibold)
        let centerRow = UIStackView(arrangedSubviews: [avatar, identity])
        centerRow.axis = .horizontal
        centerRow.alignment = .center
        centerRow.spacing = 7
        centerRow.isUserInteractionEnabled = false
        let authorButton = UIButton(type: .custom)
        authorButton.addSubview(centerRow)
        centerRow.snp.makeConstraints { $0.edges.equalToSuperview() }
        authorButton.addTarget(self, action: #selector(openAuthorProfile), for: .touchUpInside)

        let moreButton = UIButton(type: .system)
        moreButton.tintColor = VXColor.ink
        moreButton.addTarget(self, action: #selector(more), for: .touchUpInside)
        let moreGlyph = UIView()
        [0, 1].forEach { index in
            let line = UIView()
            line.backgroundColor = VXColor.ink
            line.layer.cornerRadius = 2
            moreGlyph.addSubview(line)
            line.snp.makeConstraints { make in
                make.centerX.equalToSuperview().offset(index == 0 ? 4 : -4)
                make.centerY.equalToSuperview().offset(index == 0 ? -5 : 5)
                make.width.equalTo(25)
                make.height.equalTo(4)
            }
        }
        moreGlyph.isUserInteractionEnabled = false
        moreButton.addSubview(moreGlyph)
        moreGlyph.snp.makeConstraints { $0.edges.equalToSuperview() }

        [backButton, authorButton, moreButton].forEach(header.addSubview)
        backButton.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.size.equalTo(44)
        }
        authorButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(36)
        }
        avatar.snp.makeConstraints { $0.size.equalTo(26) }
        moreButton.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.size.equalTo(44)
        }
        return header
    }

    private func makeRouteSummary() -> UIView {
        let icon = UIImageView(image: repository.user(post.authorID).map { UIImage(named: $0.role.homeAssetName) } ?? nil)
        icon.contentMode = .scaleAspectFit
        let summary = post.distance.isEmpty ? post.route : "\(post.route) · \(post.distance)"
        let text = vxLabel(summary, size: 16, color: VXColor.textSecondary)
        let row = UIStackView(arrangedSubviews: [icon, text])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 5
        icon.snp.makeConstraints { $0.size.equalTo(18) }
        return row
    }

    private func makeMediaCarousel() -> UIView {
        let container = UIView()
        container.backgroundColor = VXColor.softGreen
        container.layer.cornerRadius = 14
        container.clipsToBounds = true
        let layout = mediaCollection.collectionViewLayout as! UICollectionViewFlowLayout
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        mediaCollection.backgroundColor = VXColor.softGreen
        mediaCollection.isPagingEnabled = true
        mediaCollection.showsHorizontalScrollIndicator = false
        mediaCollection.dataSource = self
        mediaCollection.delegate = self
        mediaCollection.register(PostDetailMediaCell.self, forCellWithReuseIdentifier: "detailMedia")
        mediaPageControl.numberOfPages = max(1, post.media.count)
        mediaPageControl.currentPage = 0
        mediaPageControl.isHidden = post.media.count <= 1
        mediaPageControl.currentPageIndicatorTintColor = .white
        mediaPageControl.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.45)
        container.addSubview(mediaCollection)
        container.addSubview(mediaPageControl)
        mediaCollection.snp.makeConstraints { $0.edges.equalToSuperview() }
        mediaPageControl.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.bottom.equalToSuperview().inset(3); $0.height.equalTo(18) }
        return container
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        max(1, post.media.count)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "detailMedia", for: indexPath) as! PostDetailMediaCell
        cell.render(reference: indexPath.item < post.media.count ? post.media[indexPath.item] : nil)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < post.media.count else { return }
        present(LocalMediaFullscreenViewController(reference: post.media[indexPath.item]), animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width > 0 ? collectionView.bounds.width : view.bounds.width - 48
        let height = collectionView.bounds.height > 0 ? collectionView.bounds.height : width * 0.55
        return CGSize(width: width, height: height)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === mediaCollection, scrollView.bounds.width > 0 else { return }
        mediaPageControl.currentPage = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
    }

    private func installInputBar() {
        let inputBar = UIView()
        inputBar.backgroundColor = VXColor.canvas
        inputBar.layer.borderWidth = 0.5
        inputBar.layer.borderColor = UIColor(hex: 0xD7D8D1).cgColor

        let composeIcon = UIImageView(image: UIImage(systemName: "pencil.and.outline"))
        composeIcon.tintColor = VXColor.ink
        composeIcon.contentMode = .scaleAspectFit
        commentField.placeholder = "Say something..."
        commentField.font = VXFont.body(14)
        commentField.borderStyle = .none
        commentField.returnKeyType = .send
        commentField.addTarget(self, action: #selector(sendComment), for: .editingDidEndOnExit)

        let likeIcon = UIButton(type: .custom)
        likeIcon.setImage(UIImage(named: "good")?.withRenderingMode(.alwaysOriginal), for: .normal)
        likeIcon.addTarget(self, action: #selector(toggleLike), for: .touchUpInside)
        let commentIcon = UIImageView(image: UIImage(named: "comment"))
        commentIcon.contentMode = .scaleAspectFit
        likeIcon.snp.makeConstraints { $0.size.equalTo(24) }
        commentIcon.snp.makeConstraints { $0.size.equalTo(16) }
        let counts = UIStackView(arrangedSubviews: [likeIcon, likeCountLabel, commentIcon, commentCountLabel])
        counts.axis = .horizontal
        counts.alignment = .center
        counts.spacing = 7
        counts.setCustomSpacing(22, after: likeCountLabel)

        [composeIcon, commentField, counts].forEach(inputBar.addSubview)
        view.addSubview(inputBar)
        inputBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-40)
            make.leading.trailing.bottom.equalToSuperview()
        }
        composeIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-9)
            make.size.equalTo(20)
        }
        commentField.snp.makeConstraints { make in
            make.leading.equalTo(composeIcon.snp.trailing).offset(10)
            make.centerY.equalTo(composeIcon)
            make.height.equalTo(38)
            make.trailing.lessThanOrEqualTo(counts.snp.leading).offset(-12)
        }
        counts.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(18)
            make.centerY.equalTo(composeIcon)
        }
        scrollView.contentInset.bottom = 50
        scrollView.verticalScrollIndicatorInsets.bottom = 50
    }

    private func renderPanel() {
        detailsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if unlocked {
            detailsStack.addArrangedSubview(makeRouteCard())
            detailsStack.addArrangedSubview(makeSpecsCard())
        } else {
            detailsStack.addArrangedSubview(makeLockedCard())
        }
    }

    private func makeRouteCard() -> UIView {
        let card = outlinedCard()
        let header = sectionHeader(symbol: "map.fill", title: "GPX ROUTE")
        let routeCopy = vxLabel(post.route, size: 14, weight: .semibold, lines: 1)
        card.addSubview(header)
        card.addSubview(routeCopy)
        header.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(18)
            make.trailing.lessThanOrEqualToSuperview().inset(18)
            make.height.equalTo(36)
        }
        routeCopy.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(11)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        card.snp.makeConstraints { $0.height.equalTo(106) }
        return card
    }

    private func makeSpecsCard() -> UIView {
        let card = outlinedCard()
        let header = sectionHeader(symbol: "hammer.fill", title: "MOD SPECS")
        let order = ["EXHAUST", "SUSPENSION", "SEAT", "WHEELS", "ECU", "LIGHTING"]
        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 10
        stride(from: 0, to: order.count, by: 2).forEach { index in
            let left = specTile(key: order[index], value: post.specs[order[index]] ?? "—")
            let right = specTile(key: order[index + 1], value: post.specs[order[index + 1]] ?? "—")
            let row = UIStackView(arrangedSubviews: [left, right])
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.spacing = 10
            grid.addArrangedSubview(row)
            row.snp.makeConstraints { $0.height.equalTo(80) }
        }
        card.addSubview(header)
        card.addSubview(grid)
        header.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(18)
            make.trailing.lessThanOrEqualToSuperview().inset(18)
            make.height.equalTo(36)
        }
        grid.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(18)
            make.bottom.equalToSuperview().inset(18)
        }
        card.snp.makeConstraints { $0.height.equalTo(347) }
        return card
    }

    private func specTile(key: String, value: String) -> UIView {
        let tile = UIView()
        tile.backgroundColor = UIColor(hex: 0xFAF9F8)
        tile.layer.cornerRadius = 10
        let keyLabel = vxLabel(key, size: 10, weight: .bold, color: UIColor(hex: 0x589B32))
        let valueLabel = vxLabel(value, size: 13, weight: .semibold, lines: 2)
        tile.addSubview(keyLabel)
        tile.addSubview(valueLabel)
        keyLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(13)
            make.leading.trailing.equalToSuperview().inset(12)
        }
        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(keyLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.lessThanOrEqualToSuperview().inset(9)
        }
        return tile
    }

    private func sectionHeader(symbol: String, title: String) -> UIView {
        let iconBackground = UIView()
        iconBackground.backgroundColor = VXColor.paleLime
        iconBackground.layer.cornerRadius = 18
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = UIColor(hex: 0x65AA33)
        icon.contentMode = .scaleAspectFit
        iconBackground.addSubview(icon)
        icon.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(18) }
        iconBackground.snp.makeConstraints { $0.size.equalTo(36) }
        let titleLabel = vxLabel(title, size: 13, weight: .semibold, color: UIColor(hex: 0x589B32))
        let row = UIStackView(arrangedSubviews: [iconBackground, titleLabel])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        return row
    }

    private func outlinedCard() -> UIView {
        let card = UIView()
        card.backgroundColor = VXColor.canvas
        card.layer.borderColor = VXColor.deepLime.cgColor
        card.layer.borderWidth = 1
        card.layer.cornerRadius = 16
        card.clipsToBounds = true
        return card
    }

    private func makeLockedCard() -> UIView {
        let card = outlinedCard()
        let lockImage = UIImageView(image: UIImage(named: "lock"))
        lockImage.contentMode = .scaleAspectFit
        let title = vxLabel("GPX Route & Mod Specs\nhidden", size: 20, weight: .bold, lines: 2)
        title.textAlignment = .center
        let body = vxLabel("See every installed part, model number,\nsetup note, and rider recommendation.", size: 13, color: VXColor.textSecondary, lines: 2)
        body.textAlignment = .center
        let list = vxLabel("•  EXHAUST\n•  SUSPENSION\n•  SEAT\n•  ECU\n•  LIGHTING", size: 13, color: UIColor(hex: 0x9BA395), lines: 5)
        list.textAlignment = .center

        let unlock = UIButton(type: .system)
        unlock.setTitle("Unlock for \(post.unlockPrice) coins", for: .normal)
        unlock.setTitleColor(VXColor.ink, for: .normal)
        unlock.titleLabel?.font = VXFont.body(14, weight: .bold)
        unlock.backgroundColor = VXColor.lime
        unlock.layer.cornerRadius = 11
        unlock.addTarget(self, action: #selector(unlockPost), for: .touchUpInside)

        [lockImage, title, body, list, unlock].forEach(card.addSubview)
        lockImage.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(22)
            make.centerX.equalToSuperview()
            make.size.equalTo(38)
        }
        title.snp.makeConstraints { make in
            make.top.equalTo(lockImage.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        body.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(9)
            make.leading.trailing.equalToSuperview().inset(18)
        }
        list.snp.makeConstraints { make in
            make.top.equalTo(body.snp.bottom).offset(11)
            make.centerX.equalToSuperview()
        }
        unlock.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(13)
            make.height.equalTo(43)
        }
        card.snp.makeConstraints { $0.height.equalTo(361) }
        return card
    }

    private func renderComments() {
        commentsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        post.comments.forEach { comment in
            commentsStack.addArrangedSubview(makeCommentRow(comment))
        }
    }

    private func updateCounts() {
        likeCountLabel.text = post.likes.formatted()
        likeCountLabel.textColor = post.isLiked ? VXColor.deepLime : VXColor.ink
        commentCountLabel.text = post.comments.count.formatted()
    }

    private func makeCommentRow(_ comment: WaveComment) -> UIView {
        let row = UIView()
        let avatar = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
        avatar.tintColor = VXColor.textSecondary
        avatar.backgroundColor = VXColor.softGreen
        avatar.contentMode = .scaleAspectFill
        avatar.layer.cornerRadius = 22
        avatar.clipsToBounds = true
        let rider = repository.user(comment.authorID)
        avatar.image = rider?.displayAvatarImage ?? UIImage(systemName: "person.crop.circle.fill")
        let name = vxLabel(rider?.name ?? "Rider", size: 16, weight: .bold)
        let text = vxLabel(comment.text, size: 12, lines: 0)
        let textStack = UIStackView(arrangedSubviews: [name, text])
        textStack.axis = .vertical
        textStack.spacing = 3
        row.addSubview(avatar)
        row.addSubview(textStack)
        avatar.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.size.equalTo(44)
            make.bottom.lessThanOrEqualToSuperview()
        }
        textStack.snp.makeConstraints { make in
            make.top.trailing.bottom.equalToSuperview()
            make.leading.equalTo(avatar.snp.trailing).offset(18)
        }
        return row
    }

    @objc private func unlockPost() {
        guard LocalStore.shared.diamondBalance >= post.unlockPrice else {
            vxPresentDecision(title: "Not Enough Diamond", message: "You don't have enough diamonds to continue. Recharge now?", confirmTitle: "Confirm") {
                self.navigationController?.pushViewController(RechargeViewController(), animated: true)
            }
            return
        }
        vxPresentDecision(title: "Unlock Full Mod Specs", message: "Spend \(post.unlockPrice) diamonds to unlock Full Mod Specs?", confirmTitle: "Sure") {
            LocalStore.shared.diamondBalance -= self.post.unlockPrice
            var ids = LocalStore.shared.unlockedPostIDs
            ids.insert(self.post.id)
            LocalStore.shared.unlockedPostIDs = ids
            self.renderPanel()
        }
    }

    @objc private func sendComment() {
        guard let text = commentField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        do {
            post = try repository.addComment(postID: post.id, authorID: repository.currentUser.id, text: text)
            commentField.text = nil
            renderComments()
            updateCounts()
        } catch {
            vxAlert(title: "Unable to Comment", message: error.localizedDescription, actions: [("OK", .default, nil)])
        }
    }

    @objc private func toggleLike() {
        do {
            post = try repository.toggleLike(postID: post.id, userID: repository.currentUser.id)
            updateCounts()
        } catch {
            vxAlert(title: "Unable to Update", message: error.localizedDescription, actions: [("OK", .default, nil)])
        }
    }

    @objc private func openPostMedia() {
        guard let reference = post.media.first else { return }
        present(LocalMediaFullscreenViewController(reference: reference), animated: true)
    }

    @objc private func back() { navigationController?.popViewController(animated: true) }

    @objc private func openAuthorProfile() {
        if post.authorID == repository.currentUser.id {
            let tabs = tabBarController
            navigationController?.popToRootViewController(animated: false)
            tabs?.selectedIndex = 3
            return
        }
        guard let repository = repository as? MockDataRepository, let rider = repository.rider(post.authorID) else { return }
        let profile = SocialProfileViewController(rider: rider, repository: repository)
        profile.onBack = { [weak profile] in profile?.navigationController?.popViewController(animated: true) }
        profile.onPost = { [weak profile] preview in
            guard let id = UUID(uuidString: preview.id),
                  let selected = repository.posts(role: nil).first(where: { $0.id == id }) else { return }
            profile?.navigationController?.pushViewController(PostDetailViewController(post: selected, repository: repository), animated: true)
        }
        profile.onMore = { [weak profile] user in
            guard let profile else { return }
            let sheet = SocialMoreActionViewController(user: user, source: .profile)
            sheet.onReport = { [weak profile] user, _ in
                guard let profile, let id = UUID(uuidString: user.id) else { return }
                profile.vxOpenReport(targetUserID: id, sourceID: nil)
            }
            sheet.onBlock = { [weak profile] user, _ in
                guard let profile else { return }
                profile.present(SocialActionAlerts.blockConfirmation(user: user) { blockedUser in
                    guard let id = UUID(uuidString: blockedUser.id) else { return }
                    LocalStore.shared.block(id)
                    profile.navigationController?.popViewController(animated: true)
                }, animated: true)
            }
            profile.present(sheet, animated: true)
        }
        profile.onMessageUnavailable = { [weak profile] _ in
            guard let profile else { return }
            let prompt = SocialConnectToChatViewController()
            prompt.onOK = { [weak prompt] in prompt?.dismiss(animated: true) }
            profile.present(prompt, animated: true)
        }
        navigationController?.pushViewController(profile, animated: true)
    }

    @objc private func more() {
        if post.authorID == repository.currentUser.id {
            let sheet = VXActionSheetViewController(actions: [
                VXSheetAction("Delete", style: .danger) { [weak self] in
                    guard let self else { return }
                    self.repository.deletePost(self.post.id)
                    self.navigationController?.popViewController(animated: true)
                }
            ], compact: true)
            present(sheet, animated: true)
            return
        }
        let sheet = VXActionSheetViewController(actions: [
            VXSheetAction("Report") {
            self.vxOpenReport(targetUserID: self.post.authorID, sourceID: self.post.id)
            },
            VXSheetAction("Block", style: .destructive) {
            LocalStore.shared.block(self.post.authorID)
            self.navigationController?.popViewController(animated: true)
            }
        ])
        present(sheet, animated: true)
    }
}

private final class PostDetailMediaCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let playButton = UIImageView(image: UIImage(systemName: "play.fill"))
    private var representedID: UUID?

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        playButton.tintColor = .white
        playButton.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        playButton.contentMode = .center
        playButton.layer.cornerRadius = 25
        contentView.addSubview(imageView)
        contentView.addSubview(playButton)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        playButton.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(50) }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        representedID = nil
        imageView.image = nil
        playButton.isHidden = true
    }

    func render(reference: LocalMediaReference?) {
        guard let reference else {
            representedID = nil
            imageView.image = UIImage(named: "login_bg")
            playButton.isHidden = true
            return
        }
        representedID = reference.id
        playButton.isHidden = reference.kind != .video
        LocalMediaPreview.thumbnail(for: reference) { [weak self] image in
            guard let self, self.representedID == reference.id else { return }
            self.imageView.image = image
        }
    }
}
