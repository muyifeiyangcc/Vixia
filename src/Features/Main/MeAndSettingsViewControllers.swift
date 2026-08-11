import UIKit
import SnapKit

final class MeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let repository: VixiaRepository
    private var posts: [WavePost] = []
    private var meets: [LocalMeet] = []
    private var showsMeets = false
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    init(repository: VixiaRepository = MockDataRepository.shared) {
        self.repository = repository
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = VXColor.canvas
        navigationController?.setNavigationBarHidden(true, animated: false)

        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(WavePostCell.self, forCellWithReuseIdentifier: "post")
        collectionView.register(MeetCell.self, forCellWithReuseIdentifier: "meet")
        collectionView.register(MeProfileHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "profileHeader")
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        reloadData()
        NotificationCenter.default.addObserver(self, selector: #selector(repositoryDidChange), name: .vixiaRepositoryDidChange, object: nil)
    }

    @objc private func repositoryDidChange() { reloadData() }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    private func reloadData() {
        posts = repository.posts(authorID: repository.currentUser.id)
        meets = repository.meets(for: repository.currentUser.id)
        if isViewLoaded { collectionView.reloadData() }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        showsMeets ? meets.count : posts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if showsMeets {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "meet", for: indexPath) as! MeetCell
            let meet = meets[indexPath.item]
            cell.render(meet, host: repository.user(meet.hostID), participants: meet.attendeeIDs.compactMap(repository.user))
            cell.onJoin = { [weak self] in
                guard let self else { return }
                _ = try? self.repository.toggleMeetJoin(meetID: meet.id, userID: self.repository.currentUser.id)
            }
            return cell
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "post", for: indexPath) as! WavePostCell
        let post = posts[indexPath.item]
        cell.render(post, author: (repository as? MockDataRepository)?.rider(post.authorID))
        cell.onLike = { [weak self] in
            guard let self else { return }
            _ = try? self.repository.toggleLike(postID: post.id, userID: self.repository.currentUser.id)
        }
        cell.onComment = { [weak self] in
            guard let self else { return }
            self.navigationController?.pushViewController(PostDetailViewController(post: post, repository: self.repository), animated: true)
        }
        cell.onMore = { [weak self] in self?.presentMore(for: post) }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "profileHeader", for: indexPath) as! MeProfileHeaderView
        header.configure(user: repository.currentUser, balance: LocalStore.shared.diamondBalance, selectedIndex: showsMeets ? 1 : 0)
        header.onSettings = { [weak self] in self?.navigationController?.pushViewController(SettingsViewController(), animated: true) }
        header.onEdit = { [weak self] in self?.navigationController?.pushViewController(EditProfileViewController(), animated: true) }
        header.onBalance = { [weak self] in self?.navigationController?.pushViewController(RechargeViewController(), animated: true) }
        header.onFollowers = { [weak self] in self?.openUsers(kind: .followers) }
        header.onFollowing = { [weak self] in self?.openUsers(kind: .following) }
        header.onSegment = { [weak self, weak collectionView] index in
            guard let self, let collectionView else { return }
            showsMeets = index == 1
            collectionView.reloadData()
            collectionView.setContentOffset(.zero, animated: false)
        }
        return header
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if showsMeets {
            let meet = meets[indexPath.item]
            let detail = LocalMeetDetailViewController(meet: meet, host: repository.user(meet.hostID))
            detail.onJoinToggle = { [weak self] _ in
                guard let self else { return .failure(RepositoryMutationError.meetNotFound) }
                return Result { try self.repository.toggleMeetJoin(meetID: meet.id, userID: self.repository.currentUser.id) }
            }
            navigationController?.pushViewController(detail, animated: true)
        } else {
            navigationController?.pushViewController(PostDetailViewController(post: posts[indexPath.item], repository: repository), animated: true)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: 405)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - (showsMeets ? 32 : 24)
        return CGSize(width: width, height: showsMeets ? width * 0.71 : width * 1.24)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let inset: CGFloat = showsMeets ? 16 : 12
        return UIEdgeInsets(top: 0, left: inset, bottom: 24, right: inset)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat { 20 }

    private func openUsers(kind: SocialUsersListKind) {
        let currentID = repository.currentUser.id
        let riders = kind == .following ? repository.following(of: currentID) : repository.followers(of: currentID)
        let users = riders.map { rider in
            SocialUser(rider: rider, isFollowing: repository.isFollowing(currentID, rider.id), isMutualFollow: repository.isMutualFollow(currentID, rider.id))
        }
        let controller = SocialUsersListViewController(kind: kind, users: users)
        controller.onFollowChange = { [weak self] user, _ in
            guard let self, let targetID = UUID(uuidString: user.id) else { return }
            _ = try? self.repository.toggleFollow(followerID: currentID, followedID: targetID)
        }
        controller.onSelectUser = { [weak self] user in
            guard let self, let id = UUID(uuidString: user.id), let rider = self.repository.user(id), let core = self.repository as? MockDataRepository else { return }
            self.navigationController?.pushViewController(SocialProfileViewController(rider: rider, repository: core), animated: true)
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    private func presentMore(for post: WavePost) {
        if post.authorID == repository.currentUser.id {
            let sheet = VXActionSheetViewController(actions: [
                VXSheetAction("Delete", style: .danger) { [weak self] in
                    self?.repository.deletePost(post.id)
                    self?.reloadData()
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
                        self?.reloadData()
                    })
                ])
            }
        ])
        present(sheet, animated: true)
    }
}

private final class MeProfileHeaderView: UICollectionReusableView {
    var onSettings: (() -> Void)?
    var onEdit: (() -> Void)?
    var onBalance: (() -> Void)?
    var onFollowers: (() -> Void)?
    var onFollowing: (() -> Void)?
    var onSegment: ((Int) -> Void)?

    private let balance = UIButton(type: .system)
    private let avatar = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
    private let name = UILabel()
    private let role = UILabel()
    private let bio = UILabel()
    private let stats = UIStackView()
    private let followersTapArea = UIControl()
    private let followingTapArea = UIControl()
    private let segment = VXSegmentedPill(leftTitle: "Wave Drops", rightTitle: "Local Meets", height: 60, fontSize: 18, showsUnderline: true)

    override init(frame: CGRect) {
        super.init(frame: frame)
        let title = vxLabel("Me", size: 36, weight: .bold)

        balance.setTitleColor(VXColor.ink, for: .normal)
        balance.titleLabel?.font = VXFont.body(18, weight: .bold)
        balance.setImage(UIImage(named: "diamond")?.withRenderingMode(.alwaysOriginal), for: .normal)
        balance.backgroundColor = VXColor.lime
        balance.layer.borderWidth = 1
        balance.layer.borderColor = VXColor.deepLime.cgColor
        balance.layer.cornerRadius = 17
        balance.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 12)
        balance.imageEdgeInsets = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 7)
        balance.setContentCompressionResistancePriority(.required, for: .horizontal)
        balance.addTarget(self, action: #selector(balanceTapped), for: .touchUpInside)

        avatar.tintColor = VXColor.textMuted
        avatar.backgroundColor = VXColor.softGreen
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 42
        avatar.layer.borderWidth = 4
        avatar.layer.borderColor = UIColor(hex: 0x74848A).cgColor

        name.font = VXFont.title(23)
        name.textColor = VXColor.ink
        role.font = VXFont.body(11, weight: .semibold)
        role.backgroundColor = VXColor.softGreen
        role.layer.cornerRadius = 10
        role.clipsToBounds = true
        role.textAlignment = .center
        bio.font = VXFont.body(14)
        bio.textColor = VXColor.textSecondary
        bio.numberOfLines = 2

        stats.axis = .horizontal
        stats.distribution = .fillEqually

        let setting = profileButton("Setting", green: false)
        let edit = profileButton("Edit Profile", green: true)
        setting.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        edit.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        let actions = UIStackView(arrangedSubviews: [setting, edit])
        actions.axis = .horizontal
        actions.spacing = 10
        actions.distribution = .fillEqually
        let statsHitAreas = UIStackView(arrangedSubviews: [UIView(), followersTapArea, followingTapArea])
        statsHitAreas.axis = .horizontal
        statsHitAreas.distribution = .fillEqually

        [title, balance, avatar, name, role, bio, stats, actions, segment, statsHitAreas].forEach(addSubview)
        title.snp.makeConstraints { $0.top.equalTo(12); $0.leading.equalTo(20) }
        balance.snp.makeConstraints { $0.top.equalTo(18); $0.trailing.equalTo(-21); $0.width.greaterThanOrEqualTo(90); $0.height.equalTo(34) }
        avatar.snp.makeConstraints { $0.top.equalTo(67); $0.leading.equalTo(24); $0.size.equalTo(84) }
        name.snp.makeConstraints { $0.top.equalTo(79); $0.leading.equalTo(avatar.snp.trailing).offset(16); $0.trailing.lessThanOrEqualTo(-20) }
        role.snp.makeConstraints { $0.top.equalTo(name.snp.bottom).offset(8); $0.leading.equalTo(name); $0.height.equalTo(21); $0.width.greaterThanOrEqualTo(136) }
        bio.snp.makeConstraints { $0.top.equalTo(164); $0.leading.trailing.equalToSuperview().inset(24) }
        stats.snp.makeConstraints { $0.top.equalTo(194); $0.leading.trailing.equalToSuperview().inset(12); $0.height.equalTo(43) }
        statsHitAreas.snp.makeConstraints { $0.edges.equalTo(stats) }
        actions.snp.makeConstraints { $0.top.equalTo(258); $0.leading.trailing.equalToSuperview().inset(13); $0.height.equalTo(44) }
        segment.snp.makeConstraints { $0.top.equalTo(321); $0.leading.trailing.equalToSuperview().inset(17) }
        segment.onChange = { [weak self] index in self?.onSegment?(index) }
        followersTapArea.addTarget(self, action: #selector(followersTapped), for: .touchUpInside)
        followingTapArea.addTarget(self, action: #selector(followingTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(user: Rider, balance value: Int, selectedIndex: Int) {
        balance.setTitle(value.formatted(), for: .normal)
        name.text = user.name
        role.text = "  \(roleSymbol(user.role)) \(user.role.rawValue) · \(user.role.homeSubtitle)  "
        bio.text = user.bio
        avatar.image = user.displayAvatarImage ?? UIImage(systemName: "person.crop.circle.fill")
        segment.selectedIndex = selectedIndex
        stats.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let meetsCount = MockDataRepository.shared.meets(for: user.id).count
        [(meetsCount.formatted(), "Meets"), (user.followers.formatted(), "Followers"), (user.following.formatted(), "Following")].forEach { value, caption in
            let valueLabel = vxLabel(value, size: 22, weight: .bold)
            let captionLabel = vxLabel(caption, size: 11, color: VXColor.textSecondary)
            let column = UIStackView(arrangedSubviews: [valueLabel, captionLabel])
            column.axis = .vertical
            column.alignment = .center
            column.spacing = -2
            let control = UIControl()
            control.addSubview(column)
            column.snp.makeConstraints { $0.center.equalToSuperview() }
            if caption == "Followers" { control.addTarget(self, action: #selector(followersTapped), for: .touchUpInside) }
            if caption == "Following" { control.addTarget(self, action: #selector(followingTapped), for: .touchUpInside) }
            stats.addArrangedSubview(control)
        }
    }

    private func profileButton(_ title: String, green: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(green ? UIColor(hex: 0x4B8E17) : VXColor.ink, for: .normal)
        button.titleLabel?.font = VXFont.body(14, weight: .semibold)
        button.backgroundColor = .white
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = (green ? UIColor(hex: 0x4B8E17) : UIColor(hex: 0xD7D8D1)).cgColor
        return button
    }

    private func roleSymbol(_ role: RiderRole) -> String {
        AuthRideIdentity(rawValue: role.rawValue)?.symbol ?? ""
    }

    @objc private func settingsTapped() { onSettings?() }
    @objc private func editTapped() { onEdit?() }
    @objc private func balanceTapped() { onBalance?() }
    @objc private func followersTapped() { onFollowers?() }
    @objc private func followingTapped() { onFollowing?() }
}

final class EditProfileViewController: VXScrollViewController, UITextViewDelegate {
    private let nameField = UITextField()
    private let bioView = UITextView()
    private let bioPlaceholder = UILabel()
    private let avatar = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
    private var selectedRole: RiderRole = .dolphin { didSet { updateRoleSelection() } }
    private var avatarData: Data?
    private var roleCards: [RiderRole: IdentityCardView] = [:]
    private var dirty = false
    private lazy var avatarPicker = VXImageSourcePicker(presenter: self) { [weak self] image in
        self?.avatar.image = image.withRenderingMode(.alwaysOriginal)
        self?.avatarData = image.jpegData(compressionQuality: 0.82)
        self?.dirty = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLayout()
    }

    private func configureLayout() {
        contentStack.spacing = 0
        contentStack.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(24)
        }

        let header = makeBackHeader(title: "Edit Profile", target: self, action: #selector(back))
        let avatarHolder = UIView()
        avatar.tintColor = VXColor.textMuted
        avatar.backgroundColor = VXColor.softGreen
        avatar.contentMode = .scaleAspectFill
        avatar.layer.cornerRadius = 55
        avatar.clipsToBounds = true
        let camera = UIImageView(image: UIImage(named: "camera"))
        camera.backgroundColor = .clear
        camera.contentMode = .scaleAspectFit
        avatarHolder.addSubview(avatar)
        avatarHolder.addSubview(camera)
        avatarHolder.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(chooseAvatar)))
        avatar.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(110) }
        camera.snp.makeConstraints { $0.centerX.equalTo(avatar); $0.bottom.equalTo(avatar).inset(7); $0.size.equalTo(24) }

        let nameRow = UIView()
        nameRow.backgroundColor = VXColor.softGreen
        nameRow.layer.cornerRadius = 12
        let nameTitle = vxLabel("Name", size: 14)
        nameField.placeholder = "Please enter"
        nameField.font = VXFont.body(14)
        nameField.textAlignment = .right
        nameField.addTarget(self, action: #selector(changed), for: .editingChanged)
        nameRow.addSubview(nameTitle)
        nameRow.addSubview(nameField)
        nameTitle.snp.makeConstraints { $0.leading.equalTo(16); $0.centerY.equalToSuperview() }
        nameField.snp.makeConstraints { $0.leading.equalTo(nameTitle.snp.trailing).offset(12); $0.trailing.equalTo(-16); $0.centerY.equalToSuperview(); $0.height.equalTo(44) }

        let bioRow = UIView()
        bioRow.backgroundColor = VXColor.softGreen
        bioRow.layer.cornerRadius = 12
        let bioTitle = vxLabel("Bio", size: 14)
        bioView.backgroundColor = .clear
        bioView.font = VXFont.body(14)
        bioView.textColor = VXColor.ink
        bioView.textContainerInset = .zero
        bioView.textContainer.lineFragmentPadding = 0
        bioView.isEditable = true
        bioView.isSelectable = true
        bioView.keyboardDismissMode = .interactive
        bioView.delegate = self
        bioPlaceholder.text = "Tell us about yourself"
        bioPlaceholder.font = VXFont.body(14)
        bioPlaceholder.textColor = VXColor.textSecondary
        bioRow.addSubview(bioTitle)
        bioRow.addSubview(bioView)
        bioRow.addSubview(bioPlaceholder)
        bioTitle.snp.makeConstraints { $0.top.leading.equalTo(16) }
        bioView.snp.makeConstraints { $0.top.equalTo(bioTitle.snp.bottom).offset(10); $0.leading.trailing.equalToSuperview().inset(16); $0.bottom.equalTo(-16) }
        bioPlaceholder.snp.makeConstraints { $0.top.leading.equalTo(bioView) }

        let roles = UIStackView()
        roles.axis = .vertical
        roles.spacing = 14
        RiderRole.allCases.forEach { role in
            guard let identity = AuthRideIdentity(rawValue: role.rawValue) else { return }
            let card = IdentityCardView(identity: identity)
            card.addAction(UIAction { [weak self] _ in self?.selectedRole = role; self?.dirty = true }, for: .touchUpInside)
            roleCards[role] = card
            roles.addArrangedSubview(card)
        }

        [header, avatarHolder, nameRow, bioRow, roles].forEach(contentStack.addArrangedSubview)
        contentStack.setCustomSpacing(36, after: header)
        contentStack.setCustomSpacing(30, after: avatarHolder)
        contentStack.setCustomSpacing(18, after: nameRow)
        contentStack.setCustomSpacing(16, after: bioRow)
        header.snp.makeConstraints { $0.height.equalTo(44) }
        avatarHolder.snp.makeConstraints { $0.height.equalTo(110) }
        nameRow.snp.makeConstraints { $0.height.equalTo(52) }
        bioRow.snp.makeConstraints { $0.height.equalTo(200) }

        let save = UIButton(type: .system)
        save.setTitle("SAVE", for: .normal)
        save.setTitleColor(.white, for: .normal)
        save.titleLabel?.font = VXFont.body(18, weight: .bold)
        save.backgroundColor = .black
        save.layer.cornerRadius = 30
        save.addTarget(self, action: #selector(saveProfile), for: .touchUpInside)
        view.addSubview(save)
        save.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(37)
            make.height.equalTo(59)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(5)
        }
        scrollView.contentInset.bottom = 92
        scrollView.verticalScrollIndicatorInsets.bottom = 92

        let user = MockDataRepository.shared.currentUser
        nameField.text = user.name
        bioView.text = user.bio
        updateBioPlaceholder()
        selectedRole = user.role
        avatarData = user.avatarData
        avatar.image = user.displayAvatarImage ?? UIImage(systemName: "person.crop.circle.fill")
        updateRoleSelection()
    }

    private func updateRoleSelection() {
        roleCards.forEach { role, card in card.isSelected = role == selectedRole }
    }

    func textViewDidChange(_ textView: UITextView) {
        dirty = true
        updateBioPlaceholder()
    }

    private func updateBioPlaceholder() {
        bioPlaceholder.isHidden = !bioView.text.isEmpty
    }
    @objc private func changed() { dirty = true }
    @objc private func chooseAvatar() { avatarPicker.presentSourceSheet() }

    @objc private func saveProfile() {
        let bio = bioView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let text = nameField.text?.trimmingCharacters(in: .whitespaces), !text.isEmpty, text.count <= 40, bio.count <= 200 else {
            vxAlert(title: "Check your profile", message: "Name is required (max 40); bio is max 200 characters.", actions: [("OK", .default, nil)])
            return
        }
        let current = MockDataRepository.shared.currentUser
        _ = MockDataRepository.shared.upsertProfile(userID: current.id, name: text, role: selectedRole, birthday: current.birthday, gender: current.gender, bio: bio, avatarData: avatarData)
        dirty = false
        navigationController?.popViewController(animated: true)
    }

    @objc private func back() {
        guard dirty else { navigationController?.popViewController(animated: true); return }
        vxAlert(title: "Discard changes?", message: "Your edits have not been saved.", actions: [
            ("Keep Editing", .cancel, nil),
            ("Discard", .destructive, { self.navigationController?.popViewController(animated: true) })
        ])
    }
}

final class SettingsViewController: VXScrollViewController {
    var onSignOut: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        contentStack.spacing = 0
        contentStack.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(24)
        }

        let header = makeBackHeader(title: "Settings", target: self, action: #selector(back))
        let group = UIStackView()
        group.axis = .vertical
        group.spacing = 0
        group.backgroundColor = VXColor.canvasAlt
        group.layer.cornerRadius = 15
        group.clipsToBounds = true
        [("Privacy Policy", #selector(privacyPolicy)), ("Terms of Service", #selector(termsOfService)), ("Blacklist", #selector(blacklist)), ("Log Out", #selector(logout)), ("Delete Account", #selector(deleteAccount))].forEach { title, action in
            let row = SettingsRowButton(title: title)
            row.addTarget(self, action: action, for: .touchUpInside)
            group.addArrangedSubview(row)
            row.snp.makeConstraints { $0.height.equalTo(52) }
        }
        contentStack.addArrangedSubview(header)
        contentStack.setCustomSpacing(21, after: header)
        contentStack.addArrangedSubview(group)
        header.snp.makeConstraints { $0.height.equalTo(44) }
    }

    @objc private func back() { navigationController?.popViewController(animated: true) }
    @objc private func privacyPolicy() {
        openPolicy(kind: .privacyPolicy)
    }

    @objc private func termsOfService() {
        openPolicy(kind: .termsOfService)
    }

    private func openPolicy(kind: AuthAgreementKind) {
        navigationController?.pushViewController(
            PolicyWebViewController(title: kind.title, url: kind.url),
            animated: true
        )
    }
    @objc private func blacklist() { navigationController?.pushViewController(BlockedUsersViewController(), animated: true) }
    @objc private func logout() { vxPresentDecision(title: "Sign Out", message: "Are you sure you want to sign out of your account?", confirmTitle: "Sure") { LocalStore.shared.signOut(); LocalAccountStore.shared.clearCurrentSelection(); self.replaceWithLogin() } }
    @objc private func deleteAccount() { vxPresentDecision(title: "Delete Account", message: "Are you sure you want to delete this account? All data will be cleared after deletion and cannot be recovered.", confirmTitle: "Delete", destructive: true) {
        let userID = LocalStore.shared.signedInUserID
        if let userID {
            MockDataRepository.shared.deleteUser(userID)
            _ = LocalAccountStore.shared.deleteAccount(userID: userID)
        }
        LocalStore.shared.deleteAccountData()
        self.replaceWithLogin()
    } }
    private func replaceWithLogin() { if let scene = view.window?.windowScene, let delegate = scene.delegate as? SceneDelegate { delegate.showLogin() } }
}

private final class SettingsRowButton: UIControl {
    init(title: String) {
        super.init(frame: .zero)
        let label = vxLabel(title, size: 14)
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 8, weight: .regular)))
        chevron.tintColor = VXColor.textMuted
        addSubview(label)
        addSubview(chevron)
        label.snp.makeConstraints { $0.leading.equalTo(14); $0.centerY.equalToSuperview() }
        chevron.snp.makeConstraints { $0.trailing.equalTo(-14); $0.centerY.equalToSuperview(); $0.size.equalTo(10) }
    }

    required init?(coder: NSCoder) { fatalError() }
}

private func makeBackHeader(title: String, target: Any?, action: Selector) -> UIView {
    let header = UIView()
    let back = UIButton(type: .system)
    back.tintColor = VXColor.ink
    back.setImage(UIImage(systemName: "arrow.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)), for: .normal)
    back.addTarget(target, action: action, for: .touchUpInside)
    let titleLabel = vxLabel(title, size: 30, weight: .bold)
    header.addSubview(back)
    header.addSubview(titleLabel)
    back.snp.makeConstraints { $0.leading.centerY.equalToSuperview(); $0.size.equalTo(44) }
    titleLabel.snp.makeConstraints { $0.leading.equalTo(back.snp.trailing).offset(15); $0.centerY.equalToSuperview() }
    return header
}

final class BlockedUsersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private var users: [Rider] = []
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = VXColor.canvas
        navigationController?.setNavigationBarHidden(true, animated: false)

        let header = makeBackHeader(title: "Blocked", target: self, action: #selector(back))
        tableView.backgroundColor = VXColor.canvas
        tableView.separatorStyle = .none
        tableView.rowHeight = 80
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SocialUserCell.self, forCellReuseIdentifier: "blockedUser")
        emptyLabel.text = "No blocked users"
        emptyLabel.font = VXFont.body(14)
        emptyLabel.textColor = VXColor.textSecondary
        emptyLabel.textAlignment = .center

        view.addSubview(header)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        header.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(44)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(3)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        emptyLabel.snp.makeConstraints { $0.center.equalTo(tableView) }
        reload()
    }

    private func reload() {
        users = MockDataRepository.shared.blockedUsers()
        tableView.reloadData()
        emptyLabel.isHidden = !users.isEmpty
        tableView.isHidden = users.isEmpty
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { users.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rider = users[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "blockedUser", for: indexPath) as! SocialUserCell
        cell.configureBlocked(user: SocialUser(rider: rider))
        cell.onFollow = { [weak self] in
            LocalStore.shared.unblock(rider.id)
            self?.reload()
        }
        return cell
    }

    @objc private func back() { navigationController?.popViewController(animated: true) }
}
