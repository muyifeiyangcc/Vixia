import UIKit
import SnapKit

public final class SocialMoreActionViewController: UIViewController {
    public var onReport: ((SocialUser, SocialActionSource) -> Void)?
    public var onBlock: ((SocialUser, SocialActionSource) -> Void)?
    public var onCancel: (() -> Void)?
    private let user: SocialUser
    private let source: SocialActionSource

    public init(user: SocialUser, source: SocialActionSource) {
        self.user = user; self.source = source
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen; modalTransitionStyle = .crossDissolve
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    public override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = UIColor.black.withAlphaComponent(0.58)
        let panel = UIView(); panel.backgroundColor = .white; panel.layer.cornerRadius = 28; panel.clipsToBounds = true
        let report = actionButton("Report", #selector(reportTapped)); let block = actionButton("Block", #selector(blockTapped)); let cancel = actionButton("Cancel", #selector(cancelTapped))
        let separator = UIView(); separator.backgroundColor = UIColor(white: 0.86, alpha: 1)
        view.addSubview(panel); panel.addSubview(report); panel.addSubview(block); panel.addSubview(separator); panel.addSubview(cancel)
        panel.snp.makeConstraints { $0.leading.equalTo(13); $0.trailing.equalTo(-13); $0.bottom.equalTo(view.safeAreaLayoutGuide) }
        report.snp.makeConstraints { $0.top.equalTo(25); $0.leading.trailing.equalToSuperview(); $0.height.equalTo(60) }
        block.snp.makeConstraints { $0.top.equalTo(report.snp.bottom); $0.leading.trailing.height.equalTo(report) }
        separator.snp.makeConstraints { $0.top.equalTo(block.snp.bottom).offset(20); $0.leading.trailing.equalToSuperview(); $0.height.equalTo(0.5) }
        cancel.snp.makeConstraints { $0.top.equalTo(separator.snp.bottom); $0.leading.trailing.equalToSuperview(); $0.height.equalTo(72); $0.bottom.equalToSuperview() }
    }
    private func actionButton(_ title: String, _ selector: Selector) -> UIButton { let button = UIButton(type: .system); button.setTitle(title, for: .normal); button.setTitleColor(SocialPalette.text, for: .normal); button.titleLabel?.font = .systemFont(ofSize: 22, weight: .semibold); button.socialOnTap(self, selector); return button }
    @objc private func reportTapped() { let callback = onReport; dismiss(animated: true) { [user, source] in callback?(user, source) } }
    @objc private func blockTapped() { let callback = onBlock; dismiss(animated: true) { [user, source] in callback?(user, source) } }
    @objc private func cancelTapped() { let callback = onCancel; dismiss(animated: true) { callback?() } }
}

public final class SocialConnectToChatViewController: UIViewController {
    public var onOK: (() -> Void)?
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil); modalPresentationStyle = .overFullScreen; modalTransitionStyle = .crossDissolve
    }
    public convenience init() { self.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    public override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = UIColor.black.withAlphaComponent(0.58)
        let panel = UIImageView(image: UIImage(named: "alert_bg")?.resizableImage(withCapInsets: UIEdgeInsets(top: 44, left: 44, bottom: 44, right: 44), resizingMode: .stretch)); panel.isUserInteractionEnabled = true; panel.layer.cornerRadius = 32; panel.layer.borderWidth = 3; panel.layer.borderColor = SocialPalette.deepBrand.cgColor; panel.clipsToBounds = true
        let title = UILabel(); title.text = "Connect to Chat"; title.font = .systemFont(ofSize: 28, weight: .bold); title.textAlignment = .center
        let text = UILabel(); text.text = "Follow each other to unlock\nmessages."; text.font = .systemFont(ofSize: 14); text.textAlignment = .center; text.numberOfLines = 0
        let ok = UIButton(type: .system); ok.setTitle("OK", for: .normal); ok.setTitleColor(SocialPalette.text, for: .normal); ok.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold); ok.backgroundColor = SocialPalette.brand; ok.layer.cornerRadius = 11; ok.socialOnTap(self, #selector(okTapped))
        view.addSubview(panel); panel.addSubview(title); panel.addSubview(text); panel.addSubview(ok)
        panel.snp.makeConstraints { $0.leading.equalTo(16); $0.trailing.equalTo(-16); $0.centerY.equalTo(view.safeAreaLayoutGuide) }
        title.snp.makeConstraints { $0.top.equalTo(33); $0.leading.trailing.equalToSuperview().inset(20) }
        text.snp.makeConstraints { $0.top.equalTo(title.snp.bottom).offset(10); $0.leading.trailing.equalToSuperview().inset(28) }
        ok.snp.makeConstraints { $0.leading.equalTo(18); $0.trailing.equalTo(-18); $0.height.equalTo(44); $0.top.greaterThanOrEqualTo(text.snp.bottom).offset(16); $0.bottom.equalTo(-19) }
    }
    @objc private func okTapped() { let callback = onOK; dismiss(animated: true) { callback?() } }
}

public enum SocialActionAlerts {
    public static func blockConfirmation(user: SocialUser, onConfirm: @escaping (SocialUser) -> Void) -> UIViewController {
        VXAlertViewController(title: "Block \(user.name)?", message: "Their profile, posts, comments, and conversations will no longer be shown.", actions: [
            ("Cancel", .cancel, nil),
            ("Block", .destructive, { onConfirm(user) })
        ])
    }

    public static func reportReason(user: SocialUser, onSubmit: @escaping (SocialUser, String) -> Void) -> UIViewController {
        VXActionSheetViewController(actions: ["Inappropriate content", "Harassment", "Spam", "Other"].map { reason in
            VXSheetAction(reason) { onSubmit(user, reason) }
        })
    }
}
