import UIKit
import WebKit
import SnapKit

/// Dedicated in-app agreement destination. No business API or remote data layer is used.
final class PolicyWebViewController: UIViewController {
    private let pageTitle: String
    private let url: URL
    private let webView = WKWebView(frame: .zero)
    init(title: String = "Agreement", url: URL) {
        self.pageTitle = title
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = VXColor.canvas
        let header = VXHeaderView(title: pageTitle); header.backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        view.addSubview(header); view.addSubview(webView)
        header.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(8); $0.leading.trailing.equalToSuperview().inset(20); $0.height.equalTo(40) }
        webView.snp.makeConstraints { $0.top.equalTo(header.snp.bottom).offset(8); $0.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide) }
        webView.load(URLRequest(url: url))
    }
    @objc private func back() { navigationController?.popViewController(animated: true) }
}
