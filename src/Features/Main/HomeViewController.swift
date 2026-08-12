import UIKit
import SnapKit

final class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let repository: VixiaRepository
    private var posts: [WavePost] = []
    private var meets: [LocalMeet] = []
    private var showsMeets = false
    private var selectedRole: RiderRole?
    private var roleButtons: [HomeRoleFilterButton] = []

    private let titleLabel = vxLabel("Vixia", size: 36, weight: .heavy)
    private let balanceButton = UIButton(type: .system)
    private let segment = VXSegmentedPill(
        leftTitle: "Wave Drops",
        rightTitle: "Local Meets",
        height: 60,
        fontSize: 18,
        showsUnderline: true
    )
    private let roleScroll = UIScrollView()
    private let roleStack = UIStackView()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private var collectionTopConstraint: Constraint?
    private var meetsCollectionTopConstraint: Constraint?

    init(repository: VixiaRepository = MockDataRepository.shared) {
        self.repository = repository
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = VXColor.canvas
        navigationController?.setNavigationBarHidden(true, animated: false)

        configureBalanceButton()
        let header = UIStackView(arrangedSubviews: [titleLabel, UIView(), balanceButton])
        header.axis = .horizontal
        header.alignment = .center

        roleStack.axis = .horizontal
        roleStack.alignment = .center
        roleStack.spacing = 14
        roleScroll.showsHorizontalScrollIndicator = false
        roleScroll.addSubview(roleStack)

        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(WavePostCell.self, forCellWithReuseIdentifier: "post")
        collectionView.register(MeetCell.self, forCellWithReuseIdentifier: "meet")

        [header, segment, roleScroll, collectionView].forEach(view.addSubview)
        header.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }
        balanceButton.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(90)
            make.height.equalTo(34)
        }
        segment.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(18)
        }
        roleScroll.snp.makeConstraints { make in
            make.top.equalTo(segment.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(36)
        }
        roleStack.snp.makeConstraints { make in
            make.edges.equalTo(roleScroll.contentLayoutGuide)
            make.height.equalTo(roleScroll.frameLayoutGuide)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        collectionView.snp.makeConstraints { make in
            collectionTopConstraint = make.top.equalTo(roleScroll.snp.bottom).offset(24).constraint
            meetsCollectionTopConstraint = make.top.equalTo(segment.snp.bottom).offset(20).constraint
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        meetsCollectionTopConstraint?.deactivate()

        configureRoles()
        segment.onChange = { [weak self] index in
            guard let self else { return }
            self.showsMeets = index == 1
            self.roleScroll.isHidden = index == 1
            if index == 1 {
                self.collectionTopConstraint?.deactivate()
                self.meetsCollectionTopConstraint?.activate()
            } else {
                self.meetsCollectionTopConstraint?.deactivate()
                self.collectionTopConstraint?.activate()
            }
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.setContentOffset(.zero, animated: false)
            self.reloadLocalData()
        }
        reloadLocalData()
        NotificationCenter.default.addObserver(self, selector: #selector(repositoryDidChange), name: .vixiaRepositoryDidChange, object: nil)
    }

    @objc private func repositoryDidChange() { updateBalance(); reloadLocalData() }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateBalance()
        reloadLocalData()
    }

    private func configureBalanceButton() {
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
    }

    private func updateBalance() {
        balanceButton.setTitle(LocalStore.shared.diamondBalance.formatted(), for: .normal)
    }

    @objc private func openRecharge() {
        navigationController?.pushViewController(RechargeViewController(), animated: true)
    }

    private func configureRoles() {
        let all = HomeRoleFilterButton(title: "All", role: nil, assetName: nil)
        addRoleButton(all)
        RiderRole.allCases.forEach { role in
            addRoleButton(HomeRoleFilterButton(title: role.rawValue, role: role, assetName: role.homeAssetName))
        }
        updateRoleSelection()
    }

    private func addRoleButton(_ button: HomeRoleFilterButton) {
        button.addTarget(self, action: #selector(roleTapped(_:)), for: .touchUpInside)
        roleButtons.append(button)
        roleStack.addArrangedSubview(button)
    }

    @objc private func roleTapped(_ sender: HomeRoleFilterButton) {
        selectedRole = sender.riderRole
        updateRoleSelection()
        posts = repository.posts(role: selectedRole)
        collectionView.reloadData()
    }

    private func updateRoleSelection() {
        roleButtons.forEach { $0.setSelectedStyle($0.riderRole == selectedRole) }
    }

    private func reloadLocalData() {
        posts = repository.posts(role: selectedRole)
        meets = repository.meets()
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        showsMeets ? meets.count : posts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if showsMeets {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "meet", for: indexPath) as! MeetCell
            let meet = meets[indexPath.item]
            cell.render(meet, host: repository.user(meet.hostID), participants: meet.attendeeIDs.compactMap(repository.user))
            cell.onJoin = { [weak self] in self?.toggleJoin(meet) }
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "post", for: indexPath) as! WavePostCell
        let post = posts[indexPath.item]
        cell.render(post, author: (repository as? MockDataRepository)?.rider(post.authorID))
        cell.onAuthor = { [weak self] in self?.openProfile(for: post.authorID) }
        cell.onLike = { [weak self] in self?.toggleLike(post) }
        cell.onComment = { [weak self] in
            guard let self else { return }
            if let tab = self.tabBarController as? MainTabController, tab.isGuest {
                tab.onGuestRestriction?()
                return
            }
            self.openPost(post.id)
        }
        cell.onMore = { [weak self] in self?.presentMore(for: post) }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let tab = tabBarController as? MainTabController, tab.isGuest {
            tab.onGuestRestriction?()
            return
        }
        if showsMeets {
            let meet = meets[indexPath.item]
            let detail = LocalMeetDetailViewController(meet: meet, host: repository.user(meet.hostID))
            detail.onJoinToggle = { [weak self] _ in
                guard let self else { return .failure(RepositoryMutationError.meetNotFound) }
                return Result { try self.repository.toggleMeetJoin(meetID: meet.id, userID: self.repository.currentUser.id) }
            }
            navigationController?.pushViewController(detail, animated: true)
        } else { openPost(posts[indexPath.item].id) }
    }

    private func openPost(_ id: UUID) {
        guard let post = repository.post(id) else { return }
        navigationController?.pushViewController(PostDetailViewController(post: post, repository: repository), animated: true)
    }

    private func toggleLike(_ post: WavePost) {
        if let tab = tabBarController as? MainTabController, tab.isGuest { tab.onGuestRestriction?(); return }
        _ = try? repository.toggleLike(postID: post.id, userID: repository.currentUser.id)
    }

    private func toggleJoin(_ meet: LocalMeet) {
        if let tab = tabBarController as? MainTabController, tab.isGuest { tab.onGuestRestriction?(); return }
        _ = try? repository.toggleMeetJoin(meetID: meet.id, userID: repository.currentUser.id)
    }

    private func openProfile(for userID: UUID) {
        if let tab = tabBarController as? MainTabController, tab.isGuest { tab.onGuestRestriction?(); return }
        guard let rider = repository.user(userID), let core = repository as? MockDataRepository else { return }
        navigationController?.pushViewController(SocialProfileViewController(rider: rider, repository: core), animated: true)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = collectionView.bounds.width - (showsMeets ? 32 : 24)
        return CGSize(width: width, height: showsMeets ? width * 0.71 : width * 1.24)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        let horizontal: CGFloat = showsMeets ? 16 : 12
        return UIEdgeInsets(top: 0, left: horizontal, bottom: 24, right: horizontal)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat { 20 }

    private func presentMore(for post: WavePost) {
        if post.authorID == repository.currentUser.id {
            let sheet = VXActionSheetViewController(actions: [
                VXSheetAction("Delete", style: .danger) { [weak self] in
                    self?.repository.deletePost(post.id)
                    self?.reloadLocalData()
                }
            ], compact: true)
            present(sheet, animated: true)
            return
        }

        let sheet = VXActionSheetViewController(actions: [
            VXSheetAction("Report") { [weak self] in
                self?.vxOpenReport(targetUserID: post.authorID, sourceID: post.id)
            },
            VXSheetAction("Block", style: .destructive) { [weak self] in
                self?.vxAlert(title: "Block user?", message: "Their content and conversations will be hidden.", actions: [
                ("Cancel", .cancel, nil),
                ("Block", .destructive, {
                    LocalStore.shared.block(post.authorID)
                    self?.reloadLocalData()
                })
                ])
            }
        ])
        present(sheet, animated: true)
    }
}

private final class HomeRoleFilterButton: UIButton {
    let riderRole: RiderRole?
    private let usesTemplateIcon: Bool

    init(title: String, role: RiderRole?, assetName: String?) {
        self.riderRole = role
        self.usesTemplateIcon = assetName == nil
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        titleLabel?.font = VXFont.body(14, weight: .semibold)
        if let assetName {
            setImage(UIImage(named: assetName)?.withRenderingMode(.alwaysOriginal), for: .normal)
        } else {
            setImage(UIImage(systemName: "square.grid.2x2", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)), for: .normal)
        }
        imageView?.contentMode = .scaleAspectFit
        semanticContentAttribute = .forceLeftToRight
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        imageEdgeInsets = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 8)
        layer.cornerRadius = 18
        layer.borderWidth = 1
        snp.makeConstraints { $0.height.equalTo(36) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func setSelectedStyle(_ selected: Bool) {
        backgroundColor = selected ? UIColor(hex: 0x222725) : .white
        setTitleColor(selected ? VXColor.lime : VXColor.ink, for: .normal)
        tintColor = selected ? VXColor.lime : VXColor.ink
        layer.borderColor = (selected ? UIColor.clear : VXColor.deepLime).cgColor
        if usesTemplateIcon { imageView?.tintColor = tintColor }
    }
}

extension RiderRole {
    var homeAssetName: String {
        switch self {
        case .dolphin: return "an1"
        case .panther: return "an2"
        case .flamingo: return "an3"
        case .owl: return "an4"
        case .wolf: return "an5"
        case .fox: return "an6"
        }
    }

    var homeSubtitle: String {
        switch self {
        case .dolphin: return "Coastal Cruise"
        case .panther: return "Performance Mods"
        case .flamingo: return "Fashion Ride"
        case .owl: return "Urban Night Ride"
        case .wolf: return "Ride Leader"
        case .fox: return "City Explorer"
        }
    }
}

final class WavePostCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    var onOpen: (() -> Void)? { didSet { openGesture.isEnabled = onOpen != nil } }
    var onAuthor: (() -> Void)?
    var onLike: (() -> Void)?
    var onComment: (() -> Void)?
    var onMore: (() -> Void)?

    private let avatar = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
    private let roleIcon = UIImageView()
    private let author = vxLabel("", size: 16, weight: .semibold)
    private let role = vxLabel("", size: 13, color: VXColor.textSecondary)
    private let cover = UIImageView()
    private let title = vxLabel("", size: 16, lines: 1)
    private let lockedLabel = vxLabel("GPX Route & Mod Specs hidden", size: 13, weight: .medium)
    private let priceLabel = vxLabel("", size: 12, weight: .bold, color: .white)
    private let lockImage = UIImageView(image: UIImage(named: "pwd"))
    private let priceBadge = UIView()
    private let likeButton = HomeSocialButton(imageName: "good")
    private let commentButton = HomeSocialButton(imageName: "comment")
    private var representedMediaID: UUID?
    private lazy var openGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(openTapped))
        gesture.delegate = self
        gesture.isEnabled = false
        return gesture
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 23
        layer.masksToBounds = true
        layer.borderColor = VXColor.deepLime.cgColor
        layer.borderWidth = 1

        avatar.contentMode = .scaleAspectFill
        avatar.tintColor = VXColor.textSecondary
        avatar.backgroundColor = VXColor.softGreen
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 18

        roleIcon.contentMode = .scaleAspectFit
        let roleRow = UIStackView(arrangedSubviews: [roleIcon, role])
        roleRow.axis = .horizontal
        roleRow.alignment = .center
        roleRow.spacing = 4
        roleIcon.snp.makeConstraints { $0.size.equalTo(16) }

        let identity = UIStackView(arrangedSubviews: [author, roleRow])
        identity.axis = .vertical
        identity.alignment = .leading
        identity.spacing = 2

        let authorButton = UIButton(type: .custom)
        authorButton.addTarget(self, action: #selector(authorTapped), for: .touchUpInside)
        let identityRow = UIStackView(arrangedSubviews: [avatar, identity])
        identityRow.axis = .horizontal
        identityRow.alignment = .center
        identityRow.spacing = 10
        authorButton.addSubview(identityRow)
        identityRow.snp.makeConstraints { $0.edges.equalToSuperview() }

        let hot = vxLabel("🔥", size: 27)
        hot.textAlignment = .center
        let header = UIStackView(arrangedSubviews: [authorButton, UIView(), hot])
        header.axis = .horizontal
        header.alignment = .center

        cover.backgroundColor = VXColor.softGreen
        cover.contentMode = .scaleAspectFill
        cover.clipsToBounds = true

        let infoPanel = UIView()
        infoPanel.backgroundColor = .white
        infoPanel.layer.cornerRadius = 20
        infoPanel.layer.shadowColor = VXColor.deepLime.cgColor
        infoPanel.layer.shadowOpacity = 0.18
        infoPanel.layer.shadowRadius = 7
        infoPanel.layer.shadowOffset = CGSize(width: 0, height: 5)

        let lockedPanel = HomeDashedPanel()
        lockedPanel.backgroundColor = VXColor.lime
        let routeImage = UIImageView(image: UIImage(named: "route"))
        routeImage.contentMode = .scaleAspectFit
        lockImage.contentMode = .scaleAspectFit
        let lockedRow = UIStackView(arrangedSubviews: [routeImage, lockedLabel, UIView(), lockImage])
        lockedRow.axis = .horizontal
        lockedRow.alignment = .center
        lockedRow.spacing = 8
        lockedPanel.addSubview(lockedRow)
        lockedRow.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 13)) }
        routeImage.snp.makeConstraints { $0.size.equalTo(18) }
        lockImage.snp.makeConstraints { $0.size.equalTo(18) }

        priceBadge.backgroundColor = .black
        priceBadge.layer.cornerRadius = 11
        let diamond = UIImageView(image: UIImage(named: "diamond"))
        diamond.contentMode = .scaleAspectFit
        let priceStack = UIStackView(arrangedSubviews: [diamond, priceLabel])
        priceStack.axis = .horizontal
        priceStack.alignment = .center
        priceStack.spacing = 3
        priceBadge.addSubview(priceStack)
        priceStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 7, bottom: 2, right: 8)) }
        diamond.snp.makeConstraints { $0.size.equalTo(14) }

        infoPanel.addSubview(title)
        infoPanel.addSubview(lockedPanel)
        infoPanel.addSubview(priceBadge)
        title.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.trailing.equalToSuperview().inset(15)
        }
        lockedPanel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview().inset(14)
            make.height.equalTo(43)
        }
        priceBadge.snp.makeConstraints { make in
            make.trailing.equalTo(lockedPanel).inset(4)
            make.centerY.equalTo(lockedPanel.snp.top)
            make.height.equalTo(22)
        }

        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
        commentButton.addTarget(self, action: #selector(commentTapped), for: .touchUpInside)
        let more = UIButton(type: .system)
        more.setTitle("••• More", for: .normal)
        more.setTitleColor(VXColor.ink, for: .normal)
        more.titleLabel?.font = VXFont.body(13, weight: .medium)
        more.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)
        let social = UIStackView(arrangedSubviews: [likeButton, commentButton, UIView(), more])
        social.axis = .horizontal
        social.alignment = .center
        social.spacing = 24

        [header, cover, infoPanel, social].forEach(contentView.addSubview)
        header.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(18)
            make.height.equalTo(64)
        }
        avatar.snp.makeConstraints { $0.size.equalTo(36) }
        authorButton.snp.makeConstraints { make in
            make.width.equalTo(235)
            make.height.equalTo(44)
        }
        hot.snp.makeConstraints { $0.size.equalTo(34) }
        cover.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(cover.snp.width).multipliedBy(0.69)
        }
        infoPanel.snp.makeConstraints { make in
            make.top.equalTo(cover.snp.bottom).offset(-29)
            make.leading.trailing.equalToSuperview().inset(15)
            make.height.equalTo(100)
        }
        social.snp.makeConstraints { make in
            make.top.equalTo(infoPanel.snp.bottom).offset(13)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(30)
            make.bottom.equalToSuperview().inset(15)
        }
        contentView.addGestureRecognizer(openGesture)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        representedMediaID = nil
        cover.image = nil
        onOpen = nil
        onAuthor = nil
        onLike = nil
        onComment = nil
        onMore = nil
    }

    func render(_ post: WavePost, author rider: Rider?) {
        author.text = rider?.name ?? "Rider"
        role.text = rider.map { "\($0.role.rawValue) · \($0.role.homeSubtitle)" } ?? "Rider"
        roleIcon.image = rider.map { UIImage(named: $0.role.homeAssetName) } ?? nil
        avatar.image = rider?.displayAvatarImage ?? UIImage(systemName: "person.crop.circle.fill")

        let heading = NSMutableAttributedString(
            string: post.title,
            attributes: [.font: VXFont.body(17, weight: .bold), .foregroundColor: VXColor.ink]
        )
        heading.append(NSAttributedString(
            string: " · \(post.route)",
            attributes: [.font: VXFont.body(16), .foregroundColor: VXColor.ink]
        ))
        title.attributedText = heading
        priceLabel.text = "\(post.unlockPrice)"
        let isUnlocked = LocalStore.shared.signedInUserID == post.authorID || LocalStore.shared.unlockedPostIDs.contains(post.id)
        lockedLabel.text = isUnlocked ? "Unlocked · Tap to view" : "GPX Route & Mod Specs hidden"
        lockImage.isHidden = isUnlocked
        priceBadge.isHidden = isUnlocked
        likeButton.setText("\(post.likes)")
        likeButton.setSelectedState(post.isLiked)
        commentButton.setText("Comment  (\(post.comments.count))")

        cover.image = nil
        if let reference = post.media.first {
            representedMediaID = reference.id
            LocalMediaPreview.thumbnail(for: reference) { [weak self] image in
                guard let self, self.representedMediaID == reference.id else { return }
                self.cover.image = image
            }
        } else {
            representedMediaID = nil
        }
    }

    @objc private func authorTapped() { onAuthor?() }
    @objc private func likeTapped() { onLike?() }
    @objc private func commentTapped() { onComment?() }
    @objc private func moreTapped() { onMore?() }
    @objc private func openTapped() { onOpen?() }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var candidate: UIView? = touch.view
        while let view = candidate, view !== contentView {
            if view is UIControl { return false }
            candidate = view.superview
        }
        return true
    }
}

private final class HomeSocialButton: UIControl {
    private let iconView: UIImageView
    private let textLabel = UILabel()

    init(imageName: String) {
        iconView = UIImageView(image: UIImage(named: imageName)?.withRenderingMode(.alwaysOriginal))
        super.init(frame: .zero)
        iconView.contentMode = .scaleAspectFit
        textLabel.font = VXFont.body(13, weight: .medium)
        textLabel.textColor = VXColor.ink
        textLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [iconView, textLabel])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 7
        row.isUserInteractionEnabled = false
        addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview() }
        iconView.snp.makeConstraints { $0.size.equalTo(14) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func setText(_ text: String) {
        textLabel.text = text
        invalidateIntrinsicContentSize()
    }

    func setSelectedState(_ selected: Bool) {
        textLabel.textColor = selected ? VXColor.deepLime : VXColor.ink
        alpha = selected ? 1 : 0.82
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: 21 + textLabel.intrinsicContentSize.width, height: 30)
    }
}

private final class HomeDashedPanel: UIView {
    private let dashedBorder = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 12
        clipsToBounds = true
        dashedBorder.fillColor = UIColor.clear.cgColor
        dashedBorder.strokeColor = VXColor.ink.cgColor
        dashedBorder.lineWidth = 1.5
        dashedBorder.lineDashPattern = [3, 2]
        layer.addSublayer(dashedBorder)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        dashedBorder.frame = bounds
        dashedBorder.path = UIBezierPath(roundedRect: bounds.insetBy(dx: 0.75, dy: 0.75), cornerRadius: 12).cgPath
    }
}

final class MeetCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    var onOpen: (() -> Void)? { didSet { openGesture.isEnabled = onOpen != nil } }
    var onJoin: (() -> Void)?
    private let title = vxLabel("", size: 20, weight: .bold)
    private let dateLabel = vxLabel("", size: 10, weight: .bold)
    private let locationLabel = vxLabel("", size: 10, weight: .medium, color: .white)
    private let distanceLabel = vxLabel("", size: 10, weight: .medium, color: .white)
    private let peopleLabel = vxLabel("", size: 10, weight: .medium, color: .white)
    private let participantsMoreLabel = UILabel()
    private let hostNameLabel = vxLabel("", size: 11, weight: .bold)
    private let hero = UIImageView()
    private let hostAvatar = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
    private var participantAvatarViews: [UIImageView] = []
    private var firstParticipantLeadingConstraint: Constraint?
    private let join = UIButton(type: .system)
    private lazy var openGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(openTapped))
        gesture.delegate = self
        gesture.isEnabled = false
        return gesture
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.masksToBounds = true

        hero.image = UIImage(named: "login_bg")
        hero.backgroundColor = VXColor.softGreen
        hero.contentMode = .scaleAspectFill
        hero.clipsToBounds = true

        let shade = UIView()
        shade.backgroundColor = UIColor.black.withAlphaComponent(0.22)
        title.textColor = .white

        let dateBadge = UIView()
        dateBadge.backgroundColor = VXColor.lime
        dateBadge.layer.cornerRadius = 13.5
        let calendarIcon = UIImageView(image: UIImage(named: "calendar"))
        calendarIcon.contentMode = .scaleAspectFit
        let dateRow = UIStackView(arrangedSubviews: [calendarIcon, dateLabel])
        dateRow.axis = .horizontal
        dateRow.alignment = .center
        dateRow.spacing = 4
        dateBadge.addSubview(dateRow)
        dateRow.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 11)) }
        calendarIcon.snp.makeConstraints { $0.size.equalTo(12) }

        let participants = makeParticipantsView()
        let locationMeta = makeMetaItem(imageName: "loc", label: locationLabel, iconSize: CGSize(width: 10, height: 10))
        let distanceMeta = makeMetaItem(imageName: "mil", label: distanceLabel, iconSize: CGSize(width: 10, height: 8))
        let peopleMeta = makeMetaItem(imageName: "group", label: peopleLabel, iconSize: CGSize(width: 12, height: 12))
        locationLabel.lineBreakMode = .byTruncatingTail
        distanceLabel.lineBreakMode = .byTruncatingTail
        locationLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        distanceLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        peopleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        peopleLabel.setContentHuggingPriority(.required, for: .horizontal)
        peopleMeta.setContentCompressionResistancePriority(.required, for: .horizontal)
        let metaRow = UIStackView(arrangedSubviews: [locationMeta, separator(), distanceMeta, separator(), peopleMeta])
        metaRow.axis = .horizontal
        metaRow.alignment = .center
        metaRow.spacing = 7

        let footer = UIView()
        footer.backgroundColor = .white

        hostAvatar.tintColor = VXColor.textSecondary
        hostAvatar.backgroundColor = VXColor.softGreen
        hostAvatar.contentMode = .scaleAspectFill
        hostAvatar.layer.cornerRadius = 19
        hostAvatar.clipsToBounds = true
        let hostedBy = vxLabel("Hosted By", size: 9, color: VXColor.textSecondary)
        let hostText = UIStackView(arrangedSubviews: [hostedBy, hostNameLabel])
        hostText.axis = .vertical
        hostText.alignment = .leading
        hostText.spacing = 1
        let hostRow = UIStackView(arrangedSubviews: [hostAvatar, hostText])
        hostRow.axis = .horizontal
        hostRow.alignment = .center
        hostRow.spacing = 8
        footer.addSubview(hostRow)

        join.setTitle("Join Ride", for: .normal)
        join.setImage(UIImage(systemName: "arrow.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)), for: .normal)
        join.semanticContentAttribute = .forceRightToLeft
        join.setTitleColor(VXColor.ink, for: .normal)
        join.tintColor = VXColor.ink
        join.titleLabel?.font = VXFont.body(12, weight: .bold)
        join.backgroundColor = VXColor.lime
        join.layer.cornerRadius = 16
        join.contentEdgeInsets = UIEdgeInsets(top: 0, left: 13, bottom: 0, right: 13)
        join.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -4)
        footer.addSubview(join)

        [hero, shade, dateBadge, participants, title, metaRow, footer].forEach(contentView.addSubview)
        hero.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview(); $0.bottom.equalTo(footer.snp.top) }
        shade.snp.makeConstraints { $0.edges.equalTo(hero) }
        dateBadge.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(14)
            make.height.equalTo(27)
        }
        participants.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().inset(12)
            make.size.equalTo(CGSize(width: 82, height: 28))
        }
        title.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(metaRow.snp.top).offset(-4)
        }
        metaRow.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(footer.snp.top).offset(-11)
            make.height.equalTo(13)
        }
        footer.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(56)
        }
        hostRow.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(13)
            make.centerY.equalToSuperview()
        }
        hostAvatar.snp.makeConstraints { $0.size.equalTo(38) }
        join.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(114)
            make.height.equalTo(32)
        }
        join.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)
        contentView.addGestureRecognizer(openGesture)
    }

    required init?(coder: NSCoder) { fatalError() }

    func render(_ meet: LocalMeet, host: Rider?, participants: [Rider] = []) {
        title.text = meet.title
        hero.image = meet.coverAssetName.flatMap(UIImage.init(named:))
        dateLabel.text = Self.dateFormatter.string(from: meet.date)
        locationLabel.text = meet.location
        distanceLabel.text = meet.distance
        peopleLabel.text = "\(meet.attendees)/\(meet.capacity)"
        let visibleParticipantCount = min(participants.count, 3)
        let overflowParticipantCount = max(0, participants.count - visibleParticipantCount)
        participantsMoreLabel.text = "+\(overflowParticipantCount)"
        participantsMoreLabel.isHidden = overflowParticipantCount == 0
        let displayedItemCount = visibleParticipantCount + (overflowParticipantCount > 0 ? 1 : 0)
        let displayedWidth = displayedItemCount > 0 ? 28 + (displayedItemCount - 1) * 18 : 0
        firstParticipantLeadingConstraint?.update(offset: 82 - displayedWidth)
        hostNameLabel.text = host?.name.replacingOccurrences(of: " ", with: "_") ?? "Rider"
        hostAvatar.image = host?.displayAvatarImage ?? UIImage(systemName: "person.crop.circle.fill")
        participantAvatarViews.enumerated().forEach { index, imageView in
            imageView.isHidden = index >= visibleParticipantCount
            imageView.image = index < visibleParticipantCount
                ? (participants[index].displayAvatarImage ?? UIImage(systemName: "person.crop.circle.fill"))
                : nil
        }
        join.setTitle(meet.joined ? "Joined" : "Join Ride", for: .normal)
        join.setImage(
            meet.joined ? nil : UIImage(systemName: "arrow.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)),
            for: .normal
        )
        join.isEnabled = meet.joined || meet.attendees < meet.capacity
        join.alpha = join.isEnabled ? 1 : 0.45
    }

    @objc private func joinTapped() { onJoin?() }
    @objc private func openTapped() { onOpen?() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onOpen = nil
        onJoin = nil
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var candidate: UIView? = touch.view
        while let view = candidate, view !== contentView {
            if view is UIControl { return false }
            candidate = view.superview
        }
        return true
    }

    private func makeMetaItem(imageName: String, label: UILabel, iconSize: CGSize) -> UIView {
        let icon = UIImageView(image: UIImage(named: imageName))
        icon.contentMode = .scaleAspectFit
        icon.snp.makeConstraints { $0.size.equalTo(iconSize) }
        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 4
        return row
    }

    private func separator() -> UILabel {
        let label = vxLabel("·", size: 10, weight: .bold, color: .white)
        label.textAlignment = .center
        return label
    }

    private func makeParticipantsView() -> UIView {
        let container = UIView()
        var previous: UIView?
        (0..<3).forEach { _ in
            let avatar = UIImageView()
            avatar.backgroundColor = VXColor.softGreen
            avatar.tintColor = VXColor.textSecondary
            avatar.contentMode = .scaleAspectFill
            avatar.layer.cornerRadius = 14
            avatar.layer.borderWidth = 1
            avatar.layer.borderColor = UIColor.white.cgColor
            avatar.clipsToBounds = true
            container.addSubview(avatar)
            participantAvatarViews.append(avatar)
            avatar.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.width.equalTo(28)
                if let previous { make.leading.equalTo(previous.snp.leading).offset(18) }
                else { firstParticipantLeadingConstraint = make.leading.equalToSuperview().constraint }
            }
            previous = avatar
        }
        participantsMoreLabel.textAlignment = .center
        participantsMoreLabel.font = VXFont.body(9, weight: .semibold)
        participantsMoreLabel.textColor = .white
        participantsMoreLabel.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        participantsMoreLabel.layer.cornerRadius = 14
        participantsMoreLabel.clipsToBounds = true
        container.addSubview(participantsMoreLabel)
        participantsMoreLabel.snp.makeConstraints { make in
            make.top.bottom.trailing.equalToSuperview()
            make.width.equalTo(28)
        }
        return container
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, MMM d · h:mm a"
        return formatter
    }()
}
