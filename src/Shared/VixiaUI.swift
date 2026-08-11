import UIKit
import SnapKit

extension Rider {
    var displayAvatarImage: UIImage? {
        avatarData.flatMap(UIImage.init(data:)) ?? avatarAssetName.flatMap(UIImage.init(named:))
    }
}

class VXScrollViewController: UIViewController {
    let scrollView = UIScrollView()
    let contentView = UIView()
    let contentStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = VXColor.canvas
        scrollView.alwaysBounceVertical = true
        contentStack.axis = .vertical
        contentStack.spacing = 12
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(contentStack)
        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        contentStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(24)
        }
    }
}

final class VXHeaderView: UIView {
    let backButton = UIButton(type: .system)
    let titleLabel = UILabel()
    let trailingButton = UIButton(type: .system)

    init(title: String, showsBack: Bool = true, trailing: String? = nil) {
        super.init(frame: .zero)
        backButton.setImage(UIImage(systemName: "arrow.left"), for: .normal)
        backButton.tintColor = VXColor.ink
        backButton.isHidden = !showsBack
        titleLabel.text = title
        titleLabel.font = VXFont.title()
        titleLabel.textColor = VXColor.ink
        trailingButton.setTitle(trailing, for: .normal)
        trailingButton.setImage(trailing == nil ? UIImage(systemName: "ellipsis") : nil, for: .normal)
        trailingButton.tintColor = VXColor.ink
        let row = UIStackView(arrangedSubviews: [backButton, titleLabel, UIView(), trailingButton])
        row.axis = .horizontal; row.alignment = .center; row.spacing = 10
        addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview() }
        backButton.snp.makeConstraints { $0.size.equalTo(32) }
        trailingButton.snp.makeConstraints { $0.height.equalTo(32); $0.width.greaterThanOrEqualTo(32) }
    }
    required init?(coder: NSCoder) { fatalError() }
}

final class VXPrimaryButton: UIButton {
    init(_ title: String, lime: Bool = false) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        titleLabel?.font = VXFont.body(14, weight: .bold)
        setTitleColor(lime ? VXColor.ink : .white, for: .normal)
        backgroundColor = lime ? VXColor.lime : VXColor.ink
        vxRound(22)
        snp.makeConstraints { $0.height.equalTo(44) }
    }
    required init?(coder: NSCoder) { fatalError() }
}

final class VXSegmentedPill: UIControl {
    private let left = UIButton(type: .system)
    private let right = UIButton(type: .system)
    private let leftUnderline = VXWaveUnderlineView()
    private let rightUnderline = VXWaveUnderlineView()
    private let fontSize: CGFloat
    private let pillRadius: CGFloat
    private let showsUnderline: Bool
    var selectedIndex = 0 { didSet { update() } }
    var onChange: ((Int) -> Void)?

    init(leftTitle: String, rightTitle: String, height: CGFloat = 44, fontSize: CGFloat = 13, showsUnderline: Bool = false) {
        self.fontSize = fontSize
        self.pillRadius = height / 2
        self.showsUnderline = showsUnderline
        super.init(frame: .zero)
        backgroundColor = .white
        layer.cornerRadius = height / 2
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor; layer.shadowOpacity = 0.07; layer.shadowRadius = 6; layer.shadowOffset = CGSize(width: 0, height: 3)
        [left, right].forEach { $0.setTitleColor(VXColor.ink, for: .normal) }
        left.setTitle(leftTitle, for: .normal); right.setTitle(rightTitle, for: .normal)
        left.addTarget(self, action: #selector(selectLeft), for: .touchUpInside)
        right.addTarget(self, action: #selector(selectRight), for: .touchUpInside)
        left.addSubview(leftUnderline); right.addSubview(rightUnderline)
        [leftUnderline, rightUnderline].forEach { underline in
            underline.isHidden = !showsUnderline
            underline.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().inset(7)
                make.width.equalTo(86)
                make.height.equalTo(9)
            }
        }
        let row = UIStackView(arrangedSubviews: [left, right]); row.distribution = .fillEqually
        addSubview(row); row.snp.makeConstraints { $0.edges.equalToSuperview() }
        snp.makeConstraints { $0.height.equalTo(height) }; update()
    }
    required init?(coder: NSCoder) { fatalError() }
    @objc private func selectLeft() { selectedIndex = 0; onChange?(0) }
    @objc private func selectRight() { selectedIndex = 1; onChange?(1) }
    private func update() {
        let controls = [left, right]
        controls.enumerated().forEach { index, button in
            let selected = selectedIndex == index
            button.backgroundColor = selected ? VXColor.paleLime : .clear
            button.setTitleColor(selected ? VXColor.ink : VXColor.textSecondary, for: .normal)
            button.titleLabel?.font = VXFont.body(fontSize, weight: selected ? .bold : .semibold)
            button.layer.cornerRadius = pillRadius
            button.clipsToBounds = true
        }
        leftUnderline.isHidden = !showsUnderline || selectedIndex != 0
        rightUnderline.isHidden = !showsUnderline || selectedIndex != 1
    }
}

private final class VXWaveUnderlineView: UIView {
    private let shape = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeColor = VXColor.ink.cgColor
        shape.lineWidth = 2
        shape.lineCap = .round
        layer.addSublayer(shape)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = UIBezierPath()
        let midY = bounds.midY
        path.move(to: CGPoint(x: 0, y: midY))
        var x: CGFloat = 0
        while x < bounds.width {
            path.addCurve(
                to: CGPoint(x: min(x + 18, bounds.width), y: midY),
                controlPoint1: CGPoint(x: x + 4.5, y: midY - 5),
                controlPoint2: CGPoint(x: x + 13.5, y: midY + 5)
            )
            x += 18
        }
        shape.frame = bounds
        shape.path = path.cgPath
    }
}

final class VXField: UIStackView {
    let field = UITextField()
    init(label: String, placeholder: String, tall: Bool = false, labelSize: CGFloat = 13, fieldHeight: CGFloat? = nil) {
        super.init(frame: .zero)
        axis = .vertical; spacing = 7
        let labelView = UILabel(); labelView.text = label; labelView.font = VXFont.body(labelSize, weight: .semibold)
        field.placeholder = placeholder; field.font = VXFont.body(13); field.backgroundColor = VXColor.softGreen; field.vxRound(9)
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        field.leftViewMode = .always
        field.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        field.rightViewMode = .always
        let height = fieldHeight ?? (tall ? 90 : 44)
        let holder = UIView(); holder.addSubview(field); field.snp.makeConstraints { $0.edges.equalToSuperview(); $0.height.equalTo(height) }
        addArrangedSubview(labelView); addArrangedSubview(holder)
    }
    required init(coder: NSCoder) { fatalError() }
}

struct VXSheetAction {
    enum Style { case normal, destructive, danger }

    let title: String
    let style: Style
    let handler: () -> Void

    init(_ title: String, style: Style = .normal, handler: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.handler = handler
    }
}

/// Project-wide bottom action sheet. Its geometry follows the design reference:
/// a dimmed backdrop, one white rounded panel, centered actions and a separated Cancel row.
final class VXActionSheetViewController: UIViewController {
    private let actions: [VXSheetAction]
    private let cancelTitle: String
    private let compact: Bool

    init(actions: [VXSheetAction], cancelTitle: String = "Cancel", compact: Bool = false) {
        self.actions = actions
        self.cancelTitle = cancelTitle
        self.compact = compact
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.58)

        let panel = UIView()
        panel.backgroundColor = .white
        panel.layer.cornerRadius = 28
        panel.clipsToBounds = true

        let actionStack = UIStackView()
        actionStack.axis = .vertical
        actionStack.distribution = .fill

        actions.forEach { action in
            let button = makeButton(title: action.title, style: action.style)
            button.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                let handler = action.handler
                self.dismiss(animated: true, completion: handler)
            }, for: .touchUpInside)
            actionStack.addArrangedSubview(button)
            button.snp.makeConstraints { $0.height.equalTo(60) }
        }

        let separator = UIView()
        separator.backgroundColor = UIColor(white: 0.86, alpha: 1)
        let cancel = makeButton(title: cancelTitle, style: .normal)
        cancel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        view.addSubview(panel)
        panel.addSubview(actionStack)
        panel.addSubview(separator)
        panel.addSubview(cancel)

        panel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(13)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        actionStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(compact ? 0 : 25)
            make.leading.trailing.equalToSuperview()
        }
        separator.snp.makeConstraints { make in
            make.top.equalTo(actionStack.snp.bottom).offset(compact ? 0 : 20)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
        cancel.snp.makeConstraints { make in
            make.top.equalTo(separator.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(compact ? 56 : 72)
        }
    }

    private func makeButton(title: String, style: VXSheetAction.Style) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(style == .danger ? UIColor.systemRed : VXColor.ink, for: .normal)
        button.titleLabel?.font = VXFont.body(22, weight: .semibold)
        button.accessibilityIdentifier = style == .normal ? "sheetAction" : "destructiveSheetAction"
        return button
    }

    @objc private func cancelTapped() { dismiss(animated: true) }
}

final class VXStateView: UIView {
    let spinner = UIActivityIndicatorView(style: .medium)
    let label = UILabel()
    let retry = UIButton(type: .system)
    var onRetry: (() -> Void)?
    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = VXFont.body(); label.textColor = VXColor.textSecondary; label.textAlignment = .center; label.numberOfLines = 0
        retry.setTitle("Retry", for: .normal); retry.setTitleColor(VXColor.ink, for: .normal); retry.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [spinner, label, retry]); stack.axis = .vertical; stack.alignment = .center; stack.spacing = 10
        addSubview(stack); stack.snp.makeConstraints { $0.center.equalToSuperview(); $0.leading.trailing.equalToSuperview().inset(24) }
    }
    required init?(coder: NSCoder) { fatalError() }
    func render<Value>(_ state: LocalLoadState<Value>) {
        isHidden = false; spinner.stopAnimating(); retry.isHidden = true
        switch state { case .loading: label.text = "Reading local data…"; spinner.startAnimating(); case .empty: label.text = "Nothing here yet"; case .malformed(let text): label.text = text; retry.isHidden = false; case .loaded: isHidden = true }
    }
    func show(message: String, retryable: Bool) { isHidden = false; spinner.stopAnimating(); label.text = message; retry.isHidden = !retryable }
    @objc private func retryTapped() { onRetry?() }
}

func vxLabel(_ text: String, size: CGFloat = 14, weight: UIFont.Weight = .regular, color: UIColor = VXColor.ink, lines: Int = 1) -> UILabel {
    let label = UILabel(); label.text = text; label.font = VXFont.body(size, weight: weight); label.textColor = color; label.numberOfLines = lines; return label
}
