import UIKit
import SnapKit

final class RechargeViewController: VXScrollViewController {
    private let manager: PurchaseManager
    private var selected: DiamondProduct?
    private var productButtons: [DiamondProduct: RechargePackButton] = [:]

    private let balanceCard = UIImageView(image: UIImage(named: "recharge_bg"))
    private let balanceValue = UILabel()
    private let buy = UIButton(type: .system)
    private let productsStack = UIStackView()
    private let loadingOverlay = UIView()
    private let purchaseSpinner = UIActivityIndicatorView(style: .large)

    init(manager: PurchaseManager = .shared) {
        self.manager = manager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLayout()
        updateBalance()

        buy.addTarget(self, action: #selector(purchase), for: .touchUpInside)
        manager.onStateChange = { [weak self] state in
            DispatchQueue.main.async {
                self?.apply(state: state)
            }
        }
        manager.loadProducts()
    }

    private func configureLayout() {
        contentStack.spacing = 0
        contentStack.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(24)
        }

        let header = UIView()
        let backButton = UIButton(type: .system)
        let title = vxLabel("Recharge", size: 30, weight: .bold)
        backButton.tintColor = VXColor.ink
        backButton.setImage(
            UIImage(systemName: "arrow.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)),
            for: .normal
        )
        backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        header.addSubview(backButton)
        header.addSubview(title)
        backButton.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.size.equalTo(44)
        }
        title.snp.makeConstraints { make in
            make.leading.equalTo(backButton.snp.trailing).offset(15)
            make.centerY.equalToSuperview()
        }

        balanceCard.contentMode = .scaleAspectFill
        balanceCard.clipsToBounds = true
        balanceCard.layer.cornerRadius = 15
        balanceCard.isUserInteractionEnabled = true

        balanceValue.font = VXFont.display(32)
        balanceValue.textColor = VXColor.ink
        let unit = vxLabel("Diamonds", size: 11, weight: .bold)
        let amountRow = UIStackView(arrangedSubviews: [balanceValue, unit])
        amountRow.axis = .horizontal
        amountRow.alignment = .lastBaseline
        amountRow.spacing = 4
        let current = vxLabel("Current balance", size: 13, color: VXColor.textMuted)
        balanceCard.addSubview(amountRow)
        balanceCard.addSubview(current)
        amountRow.snp.makeConstraints { make in
            make.leading.equalTo(26)
            make.top.equalTo(35)
        }
        current.snp.makeConstraints { make in
            make.leading.equalTo(amountRow)
            make.top.equalTo(amountRow.snp.bottom).offset(2)
        }

        let sectionTitle = vxLabel("Choose a Diamond pack", size: 18, weight: .bold)

        contentStack.addArrangedSubview(header)
        contentStack.setCustomSpacing(21, after: header)
        contentStack.addArrangedSubview(balanceCard)
        contentStack.setCustomSpacing(17, after: balanceCard)
        contentStack.addArrangedSubview(sectionTitle)
        contentStack.setCustomSpacing(16, after: sectionTitle)
        productsStack.axis = .vertical
        productsStack.spacing = 16
        contentStack.addArrangedSubview(productsStack)

        header.snp.makeConstraints { $0.height.equalTo(44) }
        balanceCard.snp.makeConstraints { $0.height.equalTo(130) }

        buy.setTitle("RECHARGE", for: .normal)
        buy.setTitleColor(.white, for: .normal)
        buy.titleLabel?.font = VXFont.body(18, weight: .bold)
        buy.backgroundColor = .black
        buy.layer.cornerRadius = 30
        buy.isHidden = true
        view.addSubview(buy)
        buy.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(37)
            make.height.equalTo(59)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(5)
        }
        scrollView.contentInset.bottom = 92
        scrollView.verticalScrollIndicatorInsets.bottom = 92

        loadingOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        loadingOverlay.layer.cornerRadius = 16
        loadingOverlay.isHidden = true
        let processing = vxLabel("Processing purchase…", size: 14, weight: .semibold, color: .white)
        purchaseSpinner.color = .white
        let loadingStack = UIStackView(arrangedSubviews: [purchaseSpinner, processing])
        loadingStack.axis = .vertical
        loadingStack.alignment = .center
        loadingStack.spacing = 12
        loadingOverlay.addSubview(loadingStack)
        view.addSubview(loadingOverlay)
        loadingOverlay.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(CGSize(width: 190, height: 120)) }
        loadingStack.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    private func configureProducts(_ products: [DiamondProduct]) {
        productsStack.arrangedSubviews.forEach {
            productsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        productButtons.removeAll()
        selected = nil
        products.forEach { product in
            let button = RechargePackButton(product: product)
            button.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                selected = product
                productButtons.forEach { item, button in
                    button.isSelected = item == product
                }
            }, for: .touchUpInside)
            productButtons[product] = button
            productsStack.addArrangedSubview(button)
            button.snp.makeConstraints { $0.height.equalTo(74) }
        }
        buy.isHidden = products.isEmpty
    }

    private func showCatalogLoading() {
        configureProducts([])
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        let label = vxLabel("Loading diamond packs…", size: 14, color: VXColor.textSecondary)
        let row = UIStackView(arrangedSubviews: [spinner, label])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10
        productsStack.addArrangedSubview(row)
        row.snp.makeConstraints { $0.height.equalTo(52) }
    }

    private func showCatalogError(_ message: String) {
        configureProducts([])
        let label = vxLabel(message, size: 13, color: VXColor.textSecondary, lines: 0)
        label.textAlignment = .center
        let retry = UIButton(type: .system)
        retry.setTitle("Retry", for: .normal)
        retry.setTitleColor(VXColor.ink, for: .normal)
        retry.titleLabel?.font = VXFont.body(14, weight: .semibold)
        retry.backgroundColor = VXColor.lime
        retry.layer.cornerRadius = 18
        retry.addTarget(self, action: #selector(reloadProducts), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [label, retry])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12
        productsStack.addArrangedSubview(stack)
        retry.snp.makeConstraints { $0.height.equalTo(38) }
    }

    private func apply(state: PurchaseManagerState) {
        switch state {
        case .idle:
            setPurchaseLoading(false)
        case .loadingProducts:
            showCatalogLoading()
        case .productsLoaded(let products):
            configureProducts(products)
        case .purchasing:
            setPurchaseLoading(true)
        case .purchased(let product):
            setPurchaseLoading(false)
            updateBalance()
            vxAlert(title: "Recharge", message: "Purchase successful. \(product.diamonds.formatted()) diamonds were added.", actions: [("OK", .default, nil)])
        case .failed(let message):
            setPurchaseLoading(false)
            if productButtons.isEmpty {
                showCatalogError(message)
            } else {
                vxAlert(title: "Recharge", message: message, actions: [("OK", .default, nil)])
            }
        }
    }

    private func setPurchaseLoading(_ loading: Bool) {
        loadingOverlay.isHidden = !loading
        loading ? purchaseSpinner.startAnimating() : purchaseSpinner.stopAnimating()
        buy.isEnabled = !loading
        productsStack.isUserInteractionEnabled = !loading
    }

    private func updateBalance() {
        balanceValue.text = LocalStore.shared.diamondBalance.formatted()
    }

    @objc private func purchase() {
        guard let selected else {
            vxAlert(title: "Choose a pack", message: "Select one diamond pack first.", actions: [("OK", .default, nil)])
            return
        }
        buy.isEnabled = false
        manager.purchase(selected)
    }

    @objc private func reloadProducts() { manager.loadProducts() }

    @objc private func back() { navigationController?.popViewController(animated: true) }
}

private final class RechargePackButton: UIControl {
    private let amount = UILabel()
    private let price = UILabel()

    override var isSelected: Bool {
        didSet { updateAppearance() }
    }

    init(product: DiamondProduct) {
        super.init(frame: .zero)
        backgroundColor = .white
        layer.cornerRadius = 15
        layer.borderWidth = 1

        amount.text = "\(product.diamonds.formatted()) Diamonds"
        amount.font = VXFont.body(16, weight: .semibold)
        amount.textColor = VXColor.ink
        price.text = product.fallbackPrice
        price.font = VXFont.body(16, weight: .bold)
        price.textColor = VXColor.ink
        price.textAlignment = .right

        addSubview(amount)
        addSubview(price)
        amount.snp.makeConstraints { make in
            make.leading.equalTo(16)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(price.snp.leading).offset(-12)
        }
        price.snp.makeConstraints { make in
            make.trailing.equalTo(-16)
            make.centerY.equalToSuperview()
        }
        updateAppearance()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func updateAppearance() {
        backgroundColor = isSelected ? VXColor.lime : .white
        layer.borderColor = (isSelected ? VXColor.deepLime : UIColor(hex: 0xDDE1D6)).cgColor
    }
}
