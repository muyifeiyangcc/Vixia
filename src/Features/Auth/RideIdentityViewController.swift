import UIKit
import SnapKit

public final class RideIdentityViewController: AuthScrollViewController {
    private var draft: AuthRegistrationDraft
    private var selectedIdentity: AuthRideIdentity? { didSet { updateSelection() } }
    private var cards: [AuthRideIdentity: IdentityCardView] = [:]

    public init(draft: AuthRegistrationDraft, routeHandler: @escaping AuthRouteHandler) {
        self.draft = draft
        self.selectedIdentity = draft.identity
        super.init(routeHandler: routeHandler)
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        configureLayout()
    }

    private func configureLayout() {
        let title = UILabel()
        title.text = "CHOOSE YOUR\nRIDE IDENTITY"
        title.numberOfLines = 2
        title.font = .systemFont(ofSize: 30, weight: .heavy)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        AuthRideIdentity.allCases.forEach { identity in
            let card = IdentityCardView(identity: identity)
            card.addTarget(self, action: #selector(identityTapped(_:)), for: .touchUpInside)
            cards[identity] = card
            stack.addArrangedSubview(card)
        }
        let save = AuthPrimaryButton(title: "SAVE", height: 58)
        save.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        save.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        contentView.addSubview(title)
        contentView.addSubview(stack)
        contentView.addSubview(save)
        title.snp.makeConstraints { $0.top.equalToSuperview().offset(17); $0.leading.trailing.equalToSuperview().inset(24) }
        stack.snp.makeConstraints { $0.top.equalTo(title.snp.bottom).offset(14); $0.leading.trailing.equalToSuperview().inset(24) }
        save.snp.makeConstraints { $0.top.equalTo(stack.snp.bottom).offset(27); $0.leading.trailing.equalToSuperview().inset(37); $0.bottom.equalToSuperview().inset(15) }
        updateSelection()
    }

    @objc private func identityTapped(_ sender: IdentityCardView) { selectedIdentity = sender.identity }

    private func updateSelection() {
        cards.forEach { identity, card in card.isSelected = identity == selectedIdentity }
    }

    @objc private func saveTapped() {
        guard let selectedIdentity else {
            showMessage("Choose an Identity", message: "Please select one ride identity before saving.")
            return
        }
        draft.identity = selectedIdentity
        routeHandler(.identitySelected(draft), self)
    }
}

final class IdentityCardView: UIControl {
    let identity: AuthRideIdentity

    override var isSelected: Bool { didSet { refreshStyle() } }

    init(identity: AuthRideIdentity) {
        self.identity = identity
        super.init(frame: .zero)
        layer.cornerRadius = 16
        clipsToBounds = true
        let iconBackground = UIView()
        iconBackground.isUserInteractionEnabled = false
        iconBackground.backgroundColor = UIColor(red: 205/255, green: 213/255, blue: 180/255, alpha: 1)
        iconBackground.layer.cornerRadius = 23
        let icon = UIImageView(image: UIImage(named: identity.assetName))
        icon.contentMode = .scaleAspectFit
        icon.clipsToBounds = true
        let name = UILabel()
        name.text = identity.rawValue
        name.font = .systemFont(ofSize: 16, weight: .semibold)
        let subtitle = UILabel()
        subtitle.text = identity.subtitle
        subtitle.font = .systemFont(ofSize: 13)
        subtitle.textColor = AuthPalette.secondaryText
        addSubview(iconBackground)
        iconBackground.addSubview(icon)
        addSubview(name)
        addSubview(subtitle)
        snp.makeConstraints { $0.height.equalTo(76) }
        iconBackground.snp.makeConstraints { $0.leading.equalToSuperview().offset(14); $0.centerY.equalToSuperview(); $0.size.equalTo(46) }
        icon.snp.makeConstraints { $0.edges.equalToSuperview().inset(3) }
        name.snp.makeConstraints { $0.leading.equalTo(iconBackground.snp.trailing).offset(14); $0.top.equalToSuperview().offset(19); $0.trailing.equalToSuperview().inset(14) }
        subtitle.snp.makeConstraints { $0.leading.equalTo(name); $0.top.equalTo(name.snp.bottom).offset(2); $0.trailing.equalTo(name) }
        refreshStyle()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func refreshStyle() {
        backgroundColor = isSelected ? AuthPalette.brand : AuthPalette.field
    }
}
