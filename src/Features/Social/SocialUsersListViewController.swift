import UIKit
import SnapKit

public final class SocialUsersListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    public var onBack: (() -> Void)?
    public var onSelectUser: ((SocialUser) -> Void)?
    public var onFollowChange: ((SocialUser, Bool) -> Void)?
    public var onRetry: (() -> Void)?

    private let kind: SocialUsersListKind
    private var users: [SocialUser]
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let stateView = SocialStateView()

    public init(kind: SocialUsersListKind, users: [SocialUser]) {
        self.kind = kind; self.users = users
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad(); socialConfigureBase()
        let back = SocialIconButton(systemName: "arrow.left", pointSize: 28); back.socialOnTap(self, #selector(backTapped))
        let title = UILabel(); title.text = kind.title; title.font = .systemFont(ofSize: 30, weight: .bold); title.textColor = SocialPalette.text
        view.addSubview(back); view.addSubview(title); view.addSubview(tableView); view.addSubview(stateView)
        back.snp.makeConstraints { $0.leading.equalTo(24); $0.top.equalTo(view.safeAreaLayoutGuide).offset(12); $0.size.equalTo(44) }
        title.snp.makeConstraints { $0.leading.equalTo(back.snp.trailing).offset(15); $0.centerY.equalTo(back) }
        tableView.snp.makeConstraints { $0.top.equalTo(back.snp.bottom).offset(3); $0.leading.trailing.equalToSuperview(); $0.bottom.equalTo(view.safeAreaLayoutGuide) }
        stateView.snp.makeConstraints { $0.edges.equalTo(tableView) }
        tableView.backgroundColor = SocialPalette.page; tableView.separatorStyle = .none; tableView.rowHeight = 80; tableView.dataSource = self; tableView.delegate = self; tableView.register(SocialUserCell.self, forCellReuseIdentifier: "SocialUserCell")
        stateView.actionButton.socialOnTap(self, #selector(retryTapped)); render()
    }

    public func apply(state: SocialLoadState<[SocialUser]>) {
        guard isViewLoaded else { if case .loaded(let items) = state { users = items }; return }
        tableView.isHidden = true; stateView.isHidden = false
        switch state {
        case .loading: stateView.showLoading()
        case .empty(let message): stateView.showMessage(message, retry: false)
        case .failure(let message): stateView.showMessage(message, retry: true)
        case .loaded(let value): users = value; render()
        }
    }

    private func render() {
        tableView.reloadData(); tableView.isHidden = users.isEmpty; stateView.isHidden = !users.isEmpty
        if users.isEmpty { stateView.showMessage("No \(kind.title.lowercased()) yet", retry: false) }
    }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { users.count }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SocialUserCell", for: indexPath) as! SocialUserCell
        let user = users[indexPath.row]; cell.configure(user: user, kind: kind)
        cell.onFollow = { [weak self] in self?.toggle(at: indexPath.row) }; return cell
    }
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { onSelectUser?(users[indexPath.row]) }
    private func toggle(at index: Int) { users[index].isFollowing.toggle(); tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none); onFollowChange?(users[index], users[index].isFollowing) }
    @objc private func backTapped() { if let onBack { onBack() } else { navigationController?.popViewController(animated: true) } }
    @objc private func retryTapped() { onRetry?() }
}

final class SocialUserCell: UITableViewCell {
    var onFollow: (() -> Void)?
    private let avatar = SocialAvatarView(); private let name = UILabel(); private let detail = UILabel(); private let follow = UIButton(type: .system)
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier); backgroundColor = SocialPalette.page; selectionStyle = .none
        name.font = .systemFont(ofSize: 14, weight: .semibold); detail.font = .systemFont(ofSize: 12); detail.textColor = SocialPalette.secondary
        follow.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold); follow.setTitleColor(SocialPalette.text, for: .normal); follow.layer.cornerRadius = 12; follow.socialOnTap(self, #selector(followTapped))
        contentView.addSubview(avatar); contentView.addSubview(name); contentView.addSubview(detail); contentView.addSubview(follow)
        avatar.snp.makeConstraints { $0.leading.equalTo(24); $0.centerY.equalToSuperview(); $0.size.equalTo(44) }
        name.snp.makeConstraints { $0.leading.equalTo(avatar.snp.trailing).offset(10); $0.top.equalTo(20); $0.trailing.lessThanOrEqualTo(follow.snp.leading).offset(-8) }
        detail.snp.makeConstraints { $0.leading.equalTo(name); $0.top.equalTo(name.snp.bottom).offset(3); $0.trailing.lessThanOrEqualTo(follow.snp.leading).offset(-8) }
        follow.snp.makeConstraints { $0.trailing.equalTo(-24); $0.centerY.equalToSuperview(); $0.width.equalTo(99); $0.height.equalTo(36) }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure(user: SocialUser, kind: SocialUsersListKind) {
        avatar.configure(user: user); name.text = user.name; detail.text = "\(roleSymbol(user.role)) \(user.role) · \(user.location)"
        follow.setTitle(user.isFollowing ? "Following" : "Follow", for: .normal)
        follow.backgroundColor = user.isFollowing ? UIColor(red: 0.94, green: 0.95, blue: 0.92, alpha: 1) : SocialPalette.brand
    }

    func configureBlocked(user: SocialUser) {
        avatar.configure(user: user)
        name.text = user.name
        detail.text = "\(roleSymbol(user.role)) \(user.role) · \(user.location)"
        follow.setTitle("Unblock", for: .normal)
        follow.backgroundColor = UIColor(red: 0.94, green: 0.95, blue: 0.92, alpha: 1)
    }

    private func roleSymbol(_ role: String) -> String {
        AuthRideIdentity(rawValue: role)?.symbol ?? ""
    }
    @objc private func followTapped() { onFollow?() }
}
