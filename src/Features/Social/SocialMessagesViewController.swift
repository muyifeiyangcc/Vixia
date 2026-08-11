import UIKit
import SnapKit

public final class SocialMessagesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    public var onSelectConversation: ((SocialConversation) -> Void)?
    public var onBalance: (() -> Void)?
    public var onRetry: (() -> Void)?
    public var conversationProvider: (() -> [SocialConversation])?

    private var conversations: [SocialConversation]
    private var balance: Int
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let stateView = SocialStateView()
    private let balanceButton = UIButton(type: .system)

    public init(conversations: [SocialConversation], diamondBalance: Int) {
        self.conversations = conversations.sorted { $0.lastActivityAt > $1.lastActivityAt }
        self.balance = diamondBalance
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateBalance(LocalStore.shared.diamondBalance)
        if let conversationProvider { apply(state: .loaded(conversationProvider())) }
    }

    public override func viewDidLoad() {
        super.viewDidLoad(); socialConfigureBase()
        let title = UILabel(); title.text = "Messages"; title.font = .systemFont(ofSize: 36, weight: .bold); title.textColor = SocialPalette.text
        balanceButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        balanceButton.setTitleColor(SocialPalette.text, for: .normal)
        balanceButton.setImage(UIImage(named: "diamond")?.withRenderingMode(.alwaysOriginal), for: .normal)
        balanceButton.backgroundColor = SocialPalette.brand
        balanceButton.layer.cornerRadius = 17
        balanceButton.layer.borderWidth = 1
        balanceButton.layer.borderColor = VXColor.deepLime.cgColor
        balanceButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 12)
        balanceButton.imageEdgeInsets = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 7)
        balanceButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        balanceButton.socialOnTap(self, #selector(balanceTapped))
        view.addSubview(title); view.addSubview(balanceButton); view.addSubview(tableView); view.addSubview(stateView)
        title.snp.makeConstraints {
            $0.leading.equalTo(20)
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            $0.trailing.lessThanOrEqualTo(balanceButton.snp.leading).offset(-12)
        }
        balanceButton.snp.makeConstraints { $0.trailing.equalTo(-21); $0.centerY.equalTo(title); $0.width.greaterThanOrEqualTo(90); $0.height.equalTo(34) }
        tableView.snp.makeConstraints { $0.top.equalTo(title.snp.bottom).offset(20); $0.leading.trailing.equalToSuperview(); $0.bottom.equalTo(view.safeAreaLayoutGuide) }
        stateView.snp.makeConstraints { $0.edges.equalTo(tableView) }
        tableView.backgroundColor = SocialPalette.page; tableView.separatorStyle = .none; tableView.rowHeight = 84; tableView.dataSource = self; tableView.delegate = self; tableView.register(SocialConversationCell.self, forCellReuseIdentifier: "SocialConversationCell")
        stateView.actionButton.socialOnTap(self, #selector(retryTapped)); updateBalance(balance); render()
    }

    public func updateBalance(_ balance: Int) { self.balance = balance; if isViewLoaded { balanceButton.setTitle(balance.formatted(), for: .normal) } }

    public func apply(state: SocialLoadState<[SocialConversation]>) {
        guard isViewLoaded else { if case .loaded(let items) = state { conversations = items }; return }
        tableView.isHidden = true; stateView.isHidden = false
        switch state {
        case .loading: stateView.showLoading()
        case .empty(let message): stateView.showMessage(message, retry: false)
        case .failure(let message): stateView.showMessage(message, retry: true)
        case .loaded(let items): conversations = items.sorted { $0.lastActivityAt > $1.lastActivityAt }; render()
        }
    }

    private func render() {
        tableView.reloadData(); tableView.isHidden = conversations.isEmpty; stateView.isHidden = !conversations.isEmpty
        if conversations.isEmpty { stateView.showMessage("No conversations yet", retry: false) }
    }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { conversations.count }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SocialConversationCell", for: indexPath) as! SocialConversationCell
        cell.configure(conversation: conversations[indexPath.row]); return cell
    }
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { onSelectConversation?(conversations[indexPath.row]) }
    @objc private func balanceTapped() { onBalance?() }
    @objc private func retryTapped() { onRetry?() }
}

private final class SocialConversationCell: UITableViewCell {
    private let avatar = SocialAvatarView(); private let name = UILabel(); private let message = UILabel(); private let time = UILabel(); private let unread = UIView()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier); backgroundColor = SocialPalette.page; selectionStyle = .none
        name.font = .systemFont(ofSize: 18, weight: .bold); message.font = .systemFont(ofSize: 12, weight: .semibold); message.numberOfLines = 1
        time.font = .systemFont(ofSize: 12, weight: .semibold); time.textAlignment = .right
        unread.backgroundColor = SocialPalette.deepBrand; unread.layer.cornerRadius = 4
        let textBlock = UIView()
        textBlock.addSubview(name)
        textBlock.addSubview(message)
        contentView.addSubview(avatar); contentView.addSubview(textBlock); contentView.addSubview(time); contentView.addSubview(unread)
        textBlock.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(-18)
        }
        avatar.snp.makeConstraints { $0.leading.equalTo(18); $0.centerY.equalTo(textBlock); $0.size.equalTo(54) }
        name.snp.makeConstraints { $0.top.leading.equalToSuperview(); $0.trailing.lessThanOrEqualTo(time.snp.leading).offset(-8) }
        message.snp.makeConstraints { $0.top.equalTo(name.snp.bottom).offset(3); $0.leading.trailing.bottom.equalToSuperview() }
        time.snp.makeConstraints { $0.trailing.equalTo(-18); $0.centerY.equalTo(name); $0.width.greaterThanOrEqualTo(62) }
        unread.snp.makeConstraints { $0.trailing.equalTo(-8); $0.centerY.equalTo(time); $0.size.equalTo(8) }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure(conversation: SocialConversation) {
        avatar.configure(user: conversation.participant)
        name.text = "\(conversation.participant.name)  \(roleIcon(conversation.participant.role))"
        message.text = conversation.lastMessage
        time.text = conversation.timeText
        unread.isHidden = conversation.unreadCount == 0
    }

    private func roleIcon(_ role: String) -> String {
        switch role.lowercased() {
        case "dolphin": return "🐬"
        case "panther": return "🐈‍⬛"
        case "flamingo": return "🦩"
        case "owl": return "🦉"
        case "wolf": return "🐺"
        case "fox": return "🦊"
        default: return role
        }
    }
}
