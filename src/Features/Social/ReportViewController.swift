import UIKit
import SnapKit

final class ReportViewController: UIViewController {
    private let targetUserID: UUID
    private let sourceID: UUID?
    private let reasons = [
        "Dangerous activity or advice",
        "Harassment or hate",
        "Wildlife harm",
        "Illegal trespassing",
        "Spam or misleading content",
        "Private address or sensitive location",
        "Something else"
    ]
    private var selectedReason = "Wildlife harm"
    private var rows: [ReportReasonRow] = []
    private var hasSubmitted = false

    init(targetUserID: UUID, sourceID: UUID?) {
        self.targetUserID = targetUserID
        self.sourceID = sourceID
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = VXColor.canvas
        navigationController?.setNavigationBarHidden(true, animated: false)

        let back = UIButton(type: .system)
        back.setImage(
            UIImage(systemName: "arrow.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 27, weight: .bold)),
            for: .normal
        )
        back.tintColor = UIColor(white: 0.17, alpha: 1)
        back.addTarget(self, action: #selector(backTapped), for: .touchUpInside)

        let title = UILabel()
        title.text = "Report"
        title.textColor = VXColor.ink
        title.font = .systemFont(ofSize: 30, weight: .bold)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 11
        reasons.forEach { reason in
            let row = ReportReasonRow(title: reason)
            row.isSelected = reason == selectedReason
            row.addAction(UIAction { [weak self, weak row] _ in
                guard let self else { return }
                self.selectedReason = reason
                self.rows.forEach { $0.isSelected = $0 === row }
            }, for: .touchUpInside)
            rows.append(row)
            stack.addArrangedSubview(row)
            row.snp.makeConstraints { $0.height.equalTo(47) }
        }

        let reportButton = AuthPrimaryButton(title: "REPORT", height: 58)
        reportButton.addTarget(self, action: #selector(reportTapped), for: .touchUpInside)

        view.addSubview(back)
        view.addSubview(title)
        view.addSubview(stack)
        view.addSubview(reportButton)

        back.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(27)
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            $0.size.equalTo(44)
        }
        title.snp.makeConstraints {
            $0.leading.equalTo(back.snp.trailing).offset(11)
            $0.centerY.equalTo(back)
        }
        stack.snp.makeConstraints {
            $0.top.equalTo(back.snp.bottom).offset(26)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        reportButton.snp.makeConstraints {
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(37)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(15)
        }
    }

    @objc private func backTapped() {
        if navigationController?.topViewController === self {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func reportTapped() {
        guard !hasSubmitted else { return }
        hasSubmitted = true
        LocalStore.shared.report(targetUserID: targetUserID, sourceID: sourceID, reason: selectedReason)
        vxAlert(
            title: "Report Successful",
            message: "Your report was submitted successfully.",
            actions: [("OK", .default, { [weak self] in self?.backTapped() })]
        )
    }
}

private final class ReportReasonRow: UIControl {
    private let selectionDot = UIView()

    override var isSelected: Bool {
        didSet { selectionDot.backgroundColor = isSelected ? VXColor.lime : .white }
    }

    init(title: String) {
        super.init(frame: .zero)
        backgroundColor = UIColor(hex: 0xF8F7F5)
        layer.cornerRadius = 14

        selectionDot.backgroundColor = .white
        selectionDot.layer.cornerRadius = 9

        let label = UILabel()
        label.text = title
        label.textColor = VXColor.ink
        label.font = .systemFont(ofSize: 13, weight: .semibold)

        addSubview(selectionDot)
        addSubview(label)
        selectionDot.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(18)
        }
        label.snp.makeConstraints {
            $0.leading.equalTo(selectionDot.snp.trailing).offset(14)
            $0.trailing.lessThanOrEqualToSuperview().inset(14)
            $0.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

extension UIViewController {
    func vxOpenReport(targetUserID: UUID, sourceID: UUID?) {
        let report = ReportViewController(targetUserID: targetUserID, sourceID: sourceID)
        if let navigationController {
            navigationController.pushViewController(report, animated: true)
        } else {
            report.modalPresentationStyle = .fullScreen
            present(report, animated: true)
        }
    }
}
