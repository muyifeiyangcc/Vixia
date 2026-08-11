import UIKit
import SnapKit

public final class SocialProfileViewController: UIViewController {
    public var onBack: (() -> Void)?
    public var onMore: ((SocialUser) -> Void)?
    public var onFollowers: ((SocialUser) -> Void)?
    public var onFollowing: ((SocialUser) -> Void)?
    public var onFollowChange: ((SocialUser, Bool) -> Void)?
    public var onMessage: ((SocialUser) -> Void)?
    public var onMessageUnavailable: ((SocialUser) -> Void)?
    public var onPost: ((SocialPostPreview) -> Void)?
    public var onSegmentChange: ((SocialProfileSegment) -> Void)?
    public var onRetry: (() -> Void)?

    private var user: SocialUser
    private var posts: [SocialPostPreview]
    private var coreRider: Rider?
    private var corePosts: [WavePost] = []
    private var coreMeets: [LocalMeet] = []
    private weak var coreRepository: MockDataRepository?
    private var selectedSegment: SocialProfileSegment = .waveDrops

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let contentStack = UIStackView()
    private let avatarView = SocialAvatarView()
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    private let bioLabel = UILabel()
    private let countsStack = UIStackView()
    private let profileSegment = VXSegmentedPill(
        leftTitle: "Wave Drops",
        rightTitle: "Local Meets",
        height: 60,
        fontSize: 18,
        showsUnderline: true
    )
    private let cardsStack = UIStackView()
    private let stateView = SocialStateView()
    private let followButton = UIButton(type: .system)
    private let messageButton = UIButton(type: .system)

    public init(user: SocialUser, posts: [SocialPostPreview]) {
        self.user = user
        self.posts = posts
        super.init(nibName: nil, bundle: nil)
    }

    convenience init(rider: Rider, repository: MockDataRepository) {
        let currentID = repository.currentUser.id
        let riderPosts = repository.posts(authorID: rider.id)
        let joinedMeets = repository.meets(for: rider.id)
        var socialUser = SocialUser(rider: rider, isFollowing: repository.isFollowing(currentID, rider.id), isMutualFollow: repository.isMutualFollow(currentID, rider.id))
        socialUser.meetsCount = joinedMeets.count
        self.init(user: socialUser, posts: riderPosts.map { SocialPostPreview(post: $0, author: rider) })
        coreRider = rider
        corePosts = riderPosts
        coreMeets = joinedMeets
        coreRepository = repository
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        socialConfigureBase()
        buildLayout()
        renderProfile()
        renderPosts()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadCoreData()
    }

    private func reloadCoreData() {
        guard let repository = coreRepository, let id = UUID(uuidString: user.id), let rider = repository.user(id) else { return }
        let currentID = repository.currentUser.id
        coreRider = rider
        corePosts = repository.posts(authorID: id)
        coreMeets = repository.meets(for: id)
        user = SocialUser(rider: rider, isFollowing: repository.isFollowing(currentID, id), isMutualFollow: repository.isMutualFollow(currentID, id))
        user.meetsCount = coreMeets.count
        if isViewLoaded { renderProfile(); renderPosts() }
    }

    public func update(user: SocialUser) {
        self.user = user
        guard isViewLoaded else { return }
        renderProfile()
    }

    public func apply(state: SocialLoadState<[SocialPostPreview]>) {
        guard isViewLoaded else {
            if case .loaded(let items) = state { posts = items }
            return
        }
        cardsStack.isHidden = true
        stateView.isHidden = false
        switch state {
        case .loading: stateView.showLoading()
        case .empty(let message): stateView.showMessage(message, retry: false)
        case .failure(let message): stateView.showMessage(message, retry: true)
        case .loaded(let items): posts = items; cardsStack.isHidden = false; stateView.isHidden = true; renderPosts()
        }
    }

    private func buildLayout() {
        let back = SocialIconButton(systemName: "arrow.left", pointSize: 28)
        let more = UIButton(type: .system)
        more.tintColor = SocialPalette.text
        let moreGlyph = UIView()
        [0, 1].forEach { index in
            let line = UIView()
            line.backgroundColor = SocialPalette.text
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
        more.addSubview(moreGlyph)
        moreGlyph.snp.makeConstraints { $0.edges.equalToSuperview() }
        back.socialOnTap(self, #selector(backTapped)); more.socialOnTap(self, #selector(moreTapped))
        view.addSubview(back); view.addSubview(more); view.addSubview(scrollView)
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.addSubview(contentView)
        contentView.addSubview(contentStack)
        contentStack.axis = .vertical
        contentStack.spacing = 0

        back.snp.makeConstraints { $0.leading.equalTo(18); $0.top.equalTo(view.safeAreaLayoutGuide).offset(17); $0.size.equalTo(44) }
        more.snp.makeConstraints { $0.trailing.equalTo(-17); $0.centerY.equalTo(back); $0.size.equalTo(44) }
        scrollView.snp.makeConstraints { $0.top.equalTo(back.snp.bottom).offset(5); $0.leading.trailing.equalToSuperview() }
        contentView.snp.makeConstraints { $0.edges.equalTo(scrollView.contentLayoutGuide); $0.width.equalTo(scrollView.frameLayoutGuide) }
        contentStack.snp.makeConstraints { $0.edges.equalToSuperview(); $0.bottom.equalToSuperview() }

        let identity = UIView()
        identity.addSubview(avatarView); identity.addSubview(nameLabel); identity.addSubview(roleLabel)
        nameLabel.font = .systemFont(ofSize: 22, weight: .bold); nameLabel.textColor = SocialPalette.text
        roleLabel.font = .systemFont(ofSize: 11, weight: .semibold); roleLabel.backgroundColor = SocialPalette.softGreen; roleLabel.layer.cornerRadius = 11; roleLabel.clipsToBounds = true; roleLabel.textAlignment = .center
        avatarView.snp.makeConstraints { $0.leading.equalTo(24); $0.top.equalTo(4); $0.bottom.equalTo(-8); $0.size.equalTo(82) }
        nameLabel.snp.makeConstraints { $0.leading.equalTo(avatarView.snp.trailing).offset(17); $0.trailing.lessThanOrEqualTo(-20); $0.top.equalTo(avatarView).offset(13) }
        roleLabel.snp.makeConstraints { $0.leading.equalTo(nameLabel); $0.top.equalTo(nameLabel.snp.bottom).offset(7); $0.height.equalTo(21); $0.width.greaterThanOrEqualTo(118) }
        contentStack.addArrangedSubview(identity)

        bioLabel.font = .systemFont(ofSize: 14); bioLabel.textColor = SocialPalette.secondary; bioLabel.numberOfLines = 0
        let bioBox = inset(bioLabel, horizontal: 24, vertical: 9)
        contentStack.addArrangedSubview(bioBox)

        countsStack.axis = .horizontal; countsStack.distribution = .fillEqually
        contentStack.addArrangedSubview(countsStack)
        countsStack.snp.makeConstraints { $0.height.equalTo(60) }

        profileSegment.onChange = { [weak self] index in
            guard let self else { return }
            self.selectedSegment = index == 0 ? .waveDrops : .localMeets
            self.renderPosts()
            self.onSegmentChange?(self.selectedSegment)
        }
        let segmentBox = UIView(); segmentBox.addSubview(profileSegment)
        profileSegment.snp.makeConstraints { $0.leading.equalTo(18); $0.trailing.equalTo(-18); $0.top.equalTo(7); $0.bottom.equalTo(-14) }
        contentStack.addArrangedSubview(segmentBox)

        cardsStack.axis = .vertical; cardsStack.spacing = 20
        let cardsBox = inset(cardsStack, horizontal: 13, vertical: 0)
        contentStack.addArrangedSubview(cardsBox)
        contentStack.addArrangedSubview(stateView)
        stateView.isHidden = true; stateView.snp.makeConstraints { $0.height.equalTo(260) }
        stateView.actionButton.socialOnTap(self, #selector(retryTapped))

        let footer = UIView(); footer.backgroundColor = SocialPalette.page
        view.addSubview(footer); footer.addSubview(followButton); footer.addSubview(messageButton)
        [followButton, messageButton].forEach { $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold); $0.layer.cornerRadius = 10 }
        followButton.socialOnTap(self, #selector(followTapped)); messageButton.socialOnTap(self, #selector(messageTapped))
        messageButton.setTitle("Message", for: .normal); messageButton.setTitleColor(SocialPalette.text, for: .normal); messageButton.backgroundColor = .white; messageButton.layer.borderColor = UIColor(red: 0.84, green: 0.86, blue: 0.81, alpha: 1).cgColor; messageButton.layer.borderWidth = 1
        footer.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview(); $0.top.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-60) }
        scrollView.snp.makeConstraints { $0.bottom.equalTo(footer.snp.top) }
        followButton.snp.makeConstraints { $0.leading.equalTo(24); $0.top.equalTo(7); $0.height.equalTo(44); $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-6); $0.width.equalTo(messageButton) }
        messageButton.snp.makeConstraints { $0.leading.equalTo(followButton.snp.trailing).offset(10); $0.trailing.equalTo(-24); $0.top.height.equalTo(followButton) }
        renderSegment()
    }

    private func inset(_ child: UIView, horizontal: CGFloat, vertical: CGFloat) -> UIView {
        let box = UIView(); box.addSubview(child)
        child.snp.makeConstraints { $0.leading.equalTo(horizontal); $0.trailing.equalTo(-horizontal); $0.top.equalTo(vertical); $0.bottom.equalTo(-vertical) }
        return box
    }

    private func renderProfile() {
        avatarView.configure(user: user); nameLabel.text = user.name
        roleLabel.text = "  \(user.role) · \(roleSubtitle(user.role))  "; bioLabel.text = user.bio
        countsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        countsStack.addArrangedSubview(countButton(value: abbreviated(user.meetsCount), caption: "Meets", action: nil))
        countsStack.addArrangedSubview(countButton(value: abbreviated(user.followersCount), caption: "Followers", action: nil))
        countsStack.addArrangedSubview(countButton(value: abbreviated(user.followingCount), caption: "Following", action: nil))
        followButton.setTitle(user.isFollowing ? "Following" : "Follow", for: .normal)
        followButton.backgroundColor = user.isFollowing ? .white : SocialPalette.brand
        followButton.setTitleColor(user.isFollowing ? SocialPalette.weak : SocialPalette.text, for: .normal)
        followButton.layer.borderWidth = user.isFollowing ? 1 : 0
        followButton.layer.borderColor = UIColor(red: 0.84, green: 0.86, blue: 0.81, alpha: 1).cgColor
    }

    private func countButton(value: String, caption: String, action: Selector?) -> UIControl {
        let control = UIControl(); let valueLabel = UILabel(); let captionLabel = UILabel()
        valueLabel.text = value; valueLabel.font = .systemFont(ofSize: 24, weight: .bold); valueLabel.textColor = SocialPalette.text
        captionLabel.text = caption; captionLabel.font = .systemFont(ofSize: 12, weight: .medium); captionLabel.textColor = SocialPalette.weak
        control.addSubview(valueLabel); control.addSubview(captionLabel)
        valueLabel.snp.makeConstraints { $0.leading.equalTo(24); $0.top.equalTo(7) }
        captionLabel.snp.makeConstraints { $0.leading.equalTo(valueLabel); $0.top.equalTo(valueLabel.snp.bottom).offset(-2) }
        if let action { control.socialOnTap(self, action) }
        return control
    }

    private func abbreviated(_ count: Int) -> String { count >= 1000 ? String(format: "%.1fk", Double(count) / 1000) : "\(count)" }

    private func roleSubtitle(_ role: String) -> String {
        switch role {
        case "Dolphin": return "Coastal Cruise"
        case "Panther": return "Performance Mods"
        case "Flamingo": return "Fashion Ride"
        case "Owl": return "Urban Night Ride"
        case "Wolf": return "Ride Leader"
        case "Fox": return "City Explorer"
        default: return "Ride Identity"
        }
    }

    private func renderSegment() {
        profileSegment.selectedIndex = selectedSegment.rawValue
    }

    private func renderPosts() {
        cardsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if let coreRider {
            if selectedSegment == .waveDrops {
                if corePosts.isEmpty { showEmptyContent(); return }
                cardsStack.isHidden = false; stateView.isHidden = true
                corePosts.forEach { post in
                    let cell = WavePostCell(frame: .zero)
                    cell.render(post, author: coreRider)
                    cell.onAuthor = { }
                    cell.onOpen = { [weak self] in self?.open(post: post, author: coreRider) }
                    cell.onComment = { [weak self] in self?.open(post: post, author: coreRider) }
                    cell.onLike = { [weak self] in
                        guard let self, let repository = self.coreRepository else { return }
                        _ = try? repository.toggleLike(postID: post.id, userID: repository.currentUser.id)
                        self.reloadCoreData()
                    }
                    cell.onMore = { [weak self] in self?.presentPostActions(post) }
                    let holder = profileCardHolder(cell, ratio: 1.24)
                    cardsStack.addArrangedSubview(holder)
                }
            } else {
                if coreMeets.isEmpty { showEmptyContent(); return }
                cardsStack.isHidden = false; stateView.isHidden = true
                coreMeets.forEach { rawMeet in
                    var meet = rawMeet
                    meet.joined = true
                    let cell = MeetCell(frame: .zero)
                    cell.render(meet, host: coreRepository?.rider(meet.hostID), participants: meet.attendeeIDs.compactMap { coreRepository?.rider($0) })
                    cell.onOpen = { [weak self] in self?.open(meet: meet) }
                    cell.onJoin = { [weak self] in
                        guard let self, let repository = self.coreRepository else { return }
                        _ = try? repository.toggleMeetJoin(meetID: meet.id, userID: repository.currentUser.id)
                        self.reloadCoreData()
                    }
                    let holder = profileCardHolder(cell, ratio: 0.71)
                    cardsStack.addArrangedSubview(holder)
                }
            }
            return
        }
        if posts.isEmpty { cardsStack.isHidden = true; stateView.isHidden = false; stateView.showMessage("No content yet", retry: false); return }
        cardsStack.isHidden = false; stateView.isHidden = true
        posts.forEach { post in
            let card = SocialPostPreviewView(post: post); card.onTap = { [weak self] in self?.onPost?(post) }
            cardsStack.addArrangedSubview(card)
        }
    }

    private func profileCardHolder(_ card: UIView, ratio: CGFloat) -> UIView {
        let holder = UIView()
        holder.backgroundColor = .clear
        holder.clipsToBounds = false
        holder.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }
        holder.snp.makeConstraints { $0.height.equalTo(holder.snp.width).multipliedBy(ratio) }
        return holder
    }

    private func open(post: WavePost, author: Rider) {
        let preview = SocialPostPreview(post: post, author: author)
        if let onPost { onPost(preview) }
        else if let repository = coreRepository { navigationController?.pushViewController(PostDetailViewController(post: post, repository: repository), animated: true) }
    }

    private func open(meet: LocalMeet) {
        let detail = LocalMeetDetailViewController(meet: meet, host: coreRepository?.rider(meet.hostID))
        if let repository = coreRepository {
            detail.onJoinToggle = { _ in Result { try repository.toggleMeetJoin(meetID: meet.id, userID: repository.currentUser.id) } }
        }
        navigationController?.pushViewController(detail, animated: true)
    }

    private func presentPostActions(_ post: WavePost) {
        guard let repository = coreRepository else { return }
        if post.authorID == repository.currentUser.id {
            present(VXActionSheetViewController(actions: [VXSheetAction("Delete", style: .danger) { [weak self] in repository.deletePost(post.id); self?.reloadCoreData() }], compact: true), animated: true)
            return
        }
        present(VXActionSheetViewController(actions: [
            VXSheetAction("Report") { [weak self] in self?.vxOpenReport(targetUserID: post.authorID, sourceID: post.id) },
            VXSheetAction("Block", style: .destructive) { [weak self] in LocalStore.shared.block(post.authorID); self?.navigationController?.popViewController(animated: true) }
        ]), animated: true)
    }

    private func showEmptyContent() {
        cardsStack.isHidden = true
        stateView.isHidden = false
        stateView.showMessage("No content yet", retry: false)
    }

    @objc private func backTapped() { if let onBack { onBack() } else { navigationController?.popViewController(animated: true) } }
    @objc private func moreTapped() {
        if let onMore { onMore(user); return }
        guard let id = UUID(uuidString: user.id) else { return }
        let sheet = VXActionSheetViewController(actions: [
            VXSheetAction("Report") { [weak self] in self?.vxOpenReport(targetUserID: id, sourceID: nil) },
            VXSheetAction("Block", style: .destructive) { [weak self] in
                LocalStore.shared.block(id)
                self?.navigationController?.popViewController(animated: true)
            }
        ])
        present(sheet, animated: true)
    }
    @objc private func followersTapped() {
        if let onFollowers { onFollowers(user); return }
        openRelationshipList(.followers)
    }
    @objc private func followingTapped() {
        if let onFollowing { onFollowing(user); return }
        openRelationshipList(.following)
    }
    @objc private func retryTapped() { onRetry?() }
    @objc private func followTapped() {
        if let repository = coreRepository, let targetID = UUID(uuidString: user.id) {
            do {
                let isFollowing = try repository.toggleFollow(followerID: repository.currentUser.id, followedID: targetID)
                reloadCoreData()
                onFollowChange?(user, isFollowing)
            } catch { return }
        } else {
            user.isFollowing.toggle(); renderProfile(); onFollowChange?(user, user.isFollowing)
        }
    }
    @objc private func messageTapped() {
        guard user.isMutualFollow else {
            if let onMessageUnavailable { onMessageUnavailable(user) }
            else {
                let prompt = SocialConnectToChatViewController()
                prompt.onOK = { [weak prompt] in prompt?.dismiss(animated: true) }
                present(prompt, animated: true)
            }
            return
        }
        if let onMessage { onMessage(user); return }
        openChat()
    }

    private func openChat() {
        guard let repository = coreRepository, let peerID = UUID(uuidString: user.id) else { return }
        do {
            let currentID = repository.currentUser.id
            let raw = try repository.conversation(with: peerID, ownerID: currentID)
            let currentAvatar = repository.currentUser.displayAvatarImage
            let chat = SocialChatViewController(participant: user, currentUserID: currentID.uuidString, messages: SocialCoreAdapters.messages(conversation: raw, currentUserID: currentID, currentUserAvatar: currentAvatar))
            chat.messageLoader = { completion in
                guard let updated = repository.conversations().first(where: { $0.id == raw.id }) else { completion(.failure(RepositoryMutationError.conversationNotFound)); return }
                completion(.success(SocialCoreAdapters.messages(conversation: updated, currentUserID: currentID, currentUserAvatar: currentAvatar)))
            }
            chat.onPersistMessage = { message, completion in
                do { try repository.appendMessage(SocialCoreAdapters.chatMessage(message), to: raw.id); completion(.success(message)) }
                catch { completion(.failure(error)) }
            }
            navigationController?.pushViewController(chat, animated: true)
        } catch {
            return
        }
    }

    private func openRelationshipList(_ kind: SocialUsersListKind) {
        guard let repository = coreRepository, let profileID = UUID(uuidString: user.id) else { return }
        let riders = kind == .followers ? repository.followers(of: profileID) : repository.following(of: profileID)
        let currentID = repository.currentUser.id
        let users = riders.map { SocialUser(rider: $0, isFollowing: repository.isFollowing(currentID, $0.id), isMutualFollow: repository.isMutualFollow(currentID, $0.id)) }
        let controller = SocialUsersListViewController(kind: kind, users: users)
        controller.onFollowChange = { changed, _ in
            guard let id = UUID(uuidString: changed.id) else { return }
            _ = try? repository.toggleFollow(followerID: currentID, followedID: id)
        }
        controller.onSelectUser = { [weak self] selected in
            guard let self, let id = UUID(uuidString: selected.id), let rider = repository.user(id) else { return }
            self.navigationController?.pushViewController(SocialProfileViewController(rider: rider, repository: repository), animated: true)
        }
        navigationController?.pushViewController(controller, animated: true)
    }
}

private final class SocialPostPreviewView: UIControl {
    var onTap: (() -> Void)?
    init(post: SocialPostPreview) {
        super.init(frame: .zero)
        backgroundColor = .white; layer.cornerRadius = 20; layer.borderWidth = 1; layer.borderColor = SocialPalette.deepBrand.cgColor; clipsToBounds = true
        let author = UILabel(); author.text = post.authorName; author.font = .systemFont(ofSize: 16, weight: .bold)
        let role = UILabel(); role.text = post.authorRole; role.font = .systemFont(ofSize: 12); role.textColor = SocialPalette.secondary
        let cover = UIImageView(image: post.cover ?? post.coverName.flatMap(UIImage.init(named:))); cover.contentMode = .scaleAspectFill; cover.backgroundColor = SocialPalette.softGreen; cover.clipsToBounds = true
        let title = UILabel(); title.text = post.title; title.font = .systemFont(ofSize: 16, weight: .bold); title.numberOfLines = 1
        let subtitle = UILabel(); subtitle.text = post.subtitle; subtitle.font = .systemFont(ofSize: 14); subtitle.textColor = SocialPalette.secondary; subtitle.numberOfLines = 2
        addSubview(author); addSubview(role); addSubview(cover); addSubview(title); addSubview(subtitle)
        author.snp.makeConstraints { $0.leading.equalTo(64); $0.top.equalTo(15); $0.trailing.equalTo(-16) }
        role.snp.makeConstraints { $0.leading.trailing.equalTo(author); $0.top.equalTo(author.snp.bottom).offset(1) }
        cover.snp.makeConstraints { $0.leading.trailing.equalToSuperview(); $0.top.equalTo(54); $0.height.equalTo(cover.snp.width).multipliedBy(0.43) }
        title.snp.makeConstraints { $0.leading.equalTo(28); $0.trailing.equalTo(-20); $0.top.equalTo(cover.snp.bottom).offset(16) }
        subtitle.snp.makeConstraints { $0.leading.trailing.equalTo(title); $0.top.equalTo(title.snp.bottom).offset(5); $0.bottom.equalTo(-18) }
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    @objc private func tapped() { onTap?() }
}
