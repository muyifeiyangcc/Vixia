import UIKit
import SnapKit

public final class ProfileCompletionViewController: AuthScrollViewController, UITextFieldDelegate {
    private let draft: AuthRegistrationDraft
    private let avatarButton = UIButton(type: .system)
    private let nameField = AuthTextField(placeholder: "Please enter")
    private let birthdayRow = AuthLabeledValueRow(title: "Birthday", value: "2003-01-01", height: 52)
    private let genderRow = AuthLabeledValueRow(title: "Gender", value: "Madam", height: 52)
    private let birthdayInput = UITextField()
    private let datePicker = UIDatePicker()
    private var avatarData: Data?
    private lazy var avatarPicker = VXImageSourcePicker(presenter: self) { [weak self] image in
        self?.avatarData = image.jpegData(compressionQuality: 0.82)
        self?.avatarButton.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
    }

    public init(draft: AuthRegistrationDraft, routeHandler: @escaping AuthRouteHandler) {
        self.draft = draft
        super.init(routeHandler: routeHandler)
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        configureLayout()
        configureInputs()
    }

    private func configureLayout() {
        avatarButton.backgroundColor = .clear
        avatarButton.tintColor = UIColor(red: 190/255, green: 195/255, blue: 187/255, alpha: 1)
        let avatarConfiguration = UIImage.SymbolConfiguration(pointSize: 104, weight: .regular)
        avatarButton.setImage(UIImage(systemName: "person.crop.circle.fill", withConfiguration: avatarConfiguration), for: .normal)
        avatarButton.imageView?.contentMode = .scaleAspectFill
        avatarButton.layer.cornerRadius = 55
        avatarButton.clipsToBounds = true
        avatarButton.addTarget(self, action: #selector(chooseAvatar), for: .touchUpInside)

        let cameraBadge = UIImageView(image: UIImage(named: "camera"))
        cameraBadge.backgroundColor = .clear
        cameraBadge.contentMode = .scaleAspectFit
        cameraBadge.isUserInteractionEnabled = false

        let nameContainer = UIView()
        nameContainer.backgroundColor = AuthPalette.field
        nameContainer.layer.cornerRadius = 12
        let nameLabel = UILabel()
        nameLabel.text = "Name"
        nameLabel.font = .systemFont(ofSize: 14)
        nameField.backgroundColor = .clear
        nameField.textAlignment = .right
        nameField.leftView = nil
        nameField.clearButtonMode = .never
        nameContainer.addSubview(nameLabel)
        nameContainer.addSubview(nameField)
        nameLabel.snp.makeConstraints { $0.leading.equalToSuperview().offset(16); $0.centerY.equalToSuperview() }
        nameField.snp.makeConstraints { $0.leading.equalTo(nameLabel.snp.trailing).offset(12); $0.trailing.equalToSuperview().inset(16); $0.centerY.equalToSuperview(); $0.height.equalTo(44) }
        nameContainer.snp.makeConstraints { $0.height.equalTo(52) }

        let rows = UIStackView(arrangedSubviews: [nameContainer, birthdayRow, genderRow])
        rows.axis = .vertical
        rows.spacing = 16
        birthdayRow.addTarget(self, action: #selector(showBirthdayPicker), for: .touchUpInside)
        genderRow.addTarget(self, action: #selector(showGenderPicker), for: .touchUpInside)

        let save = AuthPrimaryButton(title: "SAVE", height: 58)
        save.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        save.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        contentView.addSubview(avatarButton)
        contentView.addSubview(cameraBadge)
        contentView.addSubview(rows)
        contentView.addSubview(birthdayInput)
        contentView.addSubview(save)
        avatarButton.snp.makeConstraints { $0.top.equalToSuperview().offset(38); $0.centerX.equalToSuperview(); $0.size.equalTo(110) }
        cameraBadge.snp.makeConstraints { $0.centerX.equalTo(avatarButton); $0.bottom.equalTo(avatarButton).inset(7); $0.size.equalTo(24) }
        rows.snp.makeConstraints { $0.top.equalTo(avatarButton.snp.bottom).offset(32); $0.leading.trailing.equalToSuperview().inset(24) }
        birthdayInput.snp.makeConstraints { $0.size.equalTo(1); $0.top.leading.equalToSuperview() }
        save.snp.makeConstraints { $0.top.greaterThanOrEqualTo(rows.snp.bottom).offset(80); $0.leading.trailing.equalToSuperview().inset(37); $0.bottom.equalToSuperview().inset(15) }
    }

    private func configureInputs() {
        nameField.delegate = self
        nameField.returnKeyType = .done
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.maximumDate = Date()
        var components = DateComponents()
        components.year = 2003
        components.month = 1
        components.day = 1
        if let date = Calendar.current.date(from: components) { datePicker.date = date }
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        birthdayInput.inputView = datePicker
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(finishDateSelection))
        ]
        birthdayInput.inputAccessoryView = toolbar
    }

    @objc private func chooseAvatar() {
        avatarPicker.presentSourceSheet()
    }

    @objc private func showBirthdayPicker() { birthdayInput.becomeFirstResponder() }
    @objc private func dateChanged() { birthdayRow.valueLabel.text = Self.dateFormatter.string(from: datePicker.date) }
    @objc private func finishDateSelection() { dateChanged(); birthdayInput.resignFirstResponder() }

    @objc private func showGenderPicker() {
        showOptions(title: "Gender", options: ["Madam", "Sir", "Prefer not to say"]) { [weak self] value in self?.genderRow.valueLabel.text = value }
    }

    private func showOptions(title: String, options: [String], selection: @escaping (String) -> Void) {
        let sheet = VXActionSheetViewController(actions: options.map { option in
            VXSheetAction(option) { selection(option) }
        })
        present(sheet, animated: true)
    }

    @objc private func saveTapped() {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else {
            showMessage("Name Required", message: "Please enter your name before saving.")
            return
        }
        let profile = AuthProfileDraft(name: name, birthday: datePicker.date, gender: genderRow.valueLabel.text ?? "", avatarData: avatarData)
        routeHandler(.profileCompleted(draft, profile), self)
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
