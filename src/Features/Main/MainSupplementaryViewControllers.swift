import UIKit
import SnapKit

final class LocalMeetDetailViewController: VXScrollViewController {
    private var meet: LocalMeet
    private let host: Rider?
    var onJoinToggle: ((LocalMeet) -> Result<LocalMeet, Error>)?
    private let joinButton = VXPrimaryButton("Join Ride →", lime: true)

    init(meet: LocalMeet, host: Rider? = nil) { self.meet = meet; self.host = host; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad()
        let header = VXHeaderView(title: "Local Meet"); header.trailingButton.isHidden = true; header.backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        let hero = UIImageView(image: meet.coverAssetName.flatMap(UIImage.init(named:))); hero.backgroundColor = VXColor.softGreen; hero.contentMode = .scaleAspectFill; hero.clipsToBounds = true; hero.vxRound(14)
        let title = vxLabel(meet.title, size: 24, weight: .bold, lines: 0)
        let date = DateFormatter.localizedString(from: meet.date, dateStyle: .medium, timeStyle: .short)
        let details = vxLabel("⌑  \(date)\n⌖  \(meet.location)\n◉  \(meet.distance)\nPeople  \(meet.attendees)/\(meet.capacity)", size: 14, color: VXColor.textSecondary, lines: 0)
        let hostLabel = vxLabel("Hosted by \(host?.name ?? "Vixia rider")", size: 14, weight: .semibold)
        [header, hero, title, details, hostLabel, joinButton].forEach(contentStack.addArrangedSubview)
        header.snp.makeConstraints { $0.height.equalTo(44) }; hero.snp.makeConstraints { $0.height.equalTo(hero.snp.width).multipliedBy(0.58) }
        joinButton.addTarget(self, action: #selector(toggleJoin), for: .touchUpInside); render()
    }
    private func render() { joinButton.setTitle(meet.joined ? "Joined ✓" : "Join Ride →", for: .normal) }
    @objc private func toggleJoin() {
        guard meet.joined || meet.attendees < meet.capacity else { vxAlert(title: "Ride Full", message: "This local meet has reached capacity.", actions: [("OK", .default, nil)]); return }
        guard let result = onJoinToggle?(meet) else { return }
        switch result { case .success(let updated): meet = updated; render(); case .failure(let error): vxAlert(title: "Unable to Save", message: error.localizedDescription, actions: [("OK", .default, nil)]) }
    }
    @objc private func back() { navigationController?.popViewController(animated: true) }
}

final class BoostViewController: UIViewController {
    var onConfirm: (() -> Result<Void, Error>)?
    private let cost: Int
    private let confirm = VXPrimaryButton("Sure", lime: true)
    init(cost: Int = 60) { self.cost = cost; super.init(nibName: nil, bundle: nil); modalPresentationStyle = .overFullScreen }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = UIColor.black.withAlphaComponent(0.56)
        let panel = UIImageView(image: UIImage(named: "alert_bg")?.resizableImage(withCapInsets: UIEdgeInsets(top: 44, left: 44, bottom: 44, right: 44), resizingMode: .stretch)); panel.isUserInteractionEnabled = true; panel.vxRound(32); panel.layer.borderWidth = 3; panel.layer.borderColor = VXColor.deepLime.cgColor
        let title = vxLabel("Boost Your Wave", size: 28, weight: .bold); title.textAlignment = .center
        let message = vxLabel("Spend \(cost) diamonds to boost this Wave Drop?\nCurrent balance: 💎 \(LocalStore.shared.diamondBalance)", size: 14, color: VXColor.textSecondary, lines: 0); message.textAlignment = .center
        let cancel = VXPrimaryButton("Cancel"); cancel.backgroundColor = VXColor.canvasAlt; cancel.setTitleColor(VXColor.ink, for: .normal); cancel.addTarget(self, action: #selector(close), for: .touchUpInside); confirm.addTarget(self, action: #selector(boost), for: .touchUpInside)
        let actions = UIStackView(arrangedSubviews: [cancel, confirm]); actions.axis = .horizontal; actions.spacing = 10; actions.distribution = .fillEqually
        let stack = UIStackView(arrangedSubviews: [title, message, actions]); stack.axis = .vertical; stack.spacing = 14; panel.addSubview(stack); stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 33, left: 18, bottom: 18, right: 18)) }
        view.addSubview(panel); panel.snp.makeConstraints { $0.centerY.equalTo(view.safeAreaLayoutGuide); $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16) }
    }
    @objc private func close() { dismiss(animated: true) }
    @objc private func boost() { confirm.isEnabled = false; guard let result = onConfirm?() else { confirm.isEnabled = true; return }; switch result { case .success: dismiss(animated: true); case .failure(let error): confirm.isEnabled = true; vxAlert(title: "Boost Failed", message: error.localizedDescription, actions: [("OK", .default, nil)]) } }
}
