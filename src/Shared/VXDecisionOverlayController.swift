import UIKit
import SnapKit

final class VXAlertViewController: UIViewController {
    typealias Action = (title: String, style: UIAlertAction.Style, handler: (() -> Void)?)

    private let dialogTitle: String
    private let dialogMessage: String
    private let actions: [Action]

    init(title: String, message: String, actions: [Action]) {
        dialogTitle = title
        dialogMessage = message
        self.actions = actions
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.56)

        let panel = UIImageView(image: Self.alertBackground)
        panel.isUserInteractionEnabled = true
        panel.layer.cornerRadius = 32
        panel.layer.borderWidth = 3
        panel.layer.borderColor = VXColor.deepLime.cgColor
        panel.clipsToBounds = true

        let title = vxLabel(dialogTitle, size: 28, weight: .bold, lines: 0)
        title.textAlignment = .center

        let messageScroll = UIScrollView()
        messageScroll.showsVerticalScrollIndicator = false
        let message = vxLabel(dialogMessage, size: 14, lines: 0)
        message.textAlignment = dialogMessage.count > 80 ? .left : .center
        messageScroll.addSubview(message)
        message.snp.makeConstraints { make in
            make.edges.equalTo(messageScroll.contentLayoutGuide)
            make.width.equalTo(messageScroll.frameLayoutGuide)
        }

        let actionsRow = UIStackView()
        actionsRow.axis = .horizontal
        actionsRow.spacing = 10
        actionsRow.distribution = .fillEqually
        actions.forEach { action in
            let button = makeButton(action)
            actionsRow.addArrangedSubview(button)
        }

        panel.addSubview(title)
        panel.addSubview(messageScroll)
        panel.addSubview(actionsRow)
        view.addSubview(panel)

        let maxHeight = min(CGFloat(732), UIScreen.main.bounds.height - 80)
        let bodyWidth = UIScreen.main.bounds.width - 88
        let titleWidth = UIScreen.main.bounds.width - 72
        let measuredTitle = ceil((dialogTitle as NSString).boundingRect(
            with: CGSize(width: titleWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: UIFont.systemFont(ofSize: 28, weight: .bold)],
            context: nil
        ).height)
        let measuredBody = ceil((dialogMessage as NSString).boundingRect(
            with: CGSize(width: bodyWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: UIFont.systemFont(ofSize: 14)],
            context: nil
        ).height)
        let fixedHeight = 119 + measuredTitle
        let minimumBodyHeight = max(CGFloat(22), 190 - fixedHeight)
        let bodyHeight = min(max(minimumBodyHeight, measuredBody), maxHeight - fixedHeight)
        let panelHeight = fixedHeight + bodyHeight
        messageScroll.isScrollEnabled = measuredBody > bodyHeight

        panel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.centerY.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(panelHeight)
        }
        title.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(33)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        messageScroll.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(28)
            make.height.equalTo(bodyHeight)
        }
        actionsRow.snp.makeConstraints { make in
            make.top.equalTo(messageScroll.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(18)
            make.bottom.equalToSuperview().inset(18)
            make.height.equalTo(44)
        }
    }

    private func makeButton(_ action: Action) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(action.title, for: .normal)
        button.titleLabel?.font = VXFont.body(14, weight: .semibold)
        button.layer.cornerRadius = 11
        if action.style == .cancel {
            button.backgroundColor = .white
            button.setTitleColor(VXColor.ink, for: .normal)
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor(hex: 0xD9DCD2).cgColor
        } else if action.style == .destructive {
            button.backgroundColor = .white
            button.setTitleColor(VXColor.warning, for: .normal)
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor(hex: 0xD9DCD2).cgColor
        } else {
            button.backgroundColor = VXColor.lime
            button.setTitleColor(VXColor.ink, for: .normal)
        }
        button.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.dismiss(animated: true, completion: action.handler)
        }, for: .touchUpInside)
        return button
    }

    private static let alertBackground: UIImage? = {
        UIImage(named: "alert_bg")?.resizableImage(
            withCapInsets: UIEdgeInsets(top: 44, left: 44, bottom: 44, right: 44),
            resizingMode: .stretch
        )
    }()
}

extension UIViewController {
    func vxPresentDecision(title: String, message: String, confirmTitle: String, destructive: Bool = false, onConfirm: @escaping () -> Void) {
        let dialog = VXAlertViewController(title: title, message: message, actions: [
            ("Cancel", .cancel, nil),
            (confirmTitle, destructive ? .destructive : .default, onConfirm)
        ])
        present(dialog, animated: true)
    }
}
