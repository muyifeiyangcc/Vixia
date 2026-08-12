import UIKit

/// Navigation stack used by each main tab. Only the root controller belongs to
/// the tab surface; every pushed destination is a full-screen secondary page.
final class VXTabNavigationController: UINavigationController {
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if !viewControllers.isEmpty {
            viewController.hidesBottomBarWhenPushed = true
        }
        super.pushViewController(viewController, animated: animated)
    }

    override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        viewControllers.enumerated().forEach { index, controller in
            controller.hidesBottomBarWhenPushed = index > 0
        }
        super.setViewControllers(viewControllers, animated: animated)
    }
}

final class MainTabController: UITabBarController, UITabBarControllerDelegate {
    var isGuest: Bool
    var onGuestRestriction: (() -> Void)?

    init(isGuest: Bool) { self.isGuest = isGuest; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad(); delegate = self
        tabBar.tintColor = VXColor.ink; tabBar.unselectedItemTintColor = VXColor.ink; tabBar.backgroundColor = .white
        tabBar.selectionIndicatorImage = makeSelectionIndicator()
        let home = VXTabNavigationController(rootViewController: HomeViewController())
        let publish = VXTabNavigationController(rootViewController: PublishViewController())
        let messages = VXTabNavigationController(rootViewController: makeMessagesController())
        let me = VXTabNavigationController(rootViewController: MeViewController())
        home.tabBarItem = tabItem(normal: "tab1", selected: "tab1_sel")
        publish.tabBarItem = tabItem(normal: "tab2", selected: "tab2_sel")
        messages.tabBarItem = tabItem(normal: "tab3", selected: "tab3_sel")
        me.tabBarItem = tabItem(normal: "tab4", selected: "tab4_sel")
        viewControllers = [home, publish, messages, me]
    }

    private func tabItem(normal: String, selected: String) -> UITabBarItem {
        UITabBarItem(
            title: nil,
            image: UIImage(named: normal)?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: selected)?.withRenderingMode(.alwaysOriginal)
        )
    }

    private func makeSelectionIndicator() -> UIImage? {
        let itemWidth = max(view.bounds.width, UIScreen.main.bounds.width) / 4
        let size = CGSize(width: itemWidth, height: 49)
        return UIGraphicsImageRenderer(size: size).image { _ in
            let rect = CGRect(x: (itemWidth - 58) / 2, y: 4, width: 58, height: 42)
            VXColor.paleLime.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 21).fill()
        }.withRenderingMode(.alwaysOriginal)
    }

    private func makeMessagesController() -> UIViewController {
        let repository = MockDataRepository.shared
        let currentID = repository.currentUser.id
        let controller = SocialMessagesViewController(conversations: SocialCoreAdapters.conversations(repository: repository, currentUserID: currentID), diamondBalance: LocalStore.shared.diamondBalance)
        controller.conversationProvider = {
            SocialCoreAdapters.conversations(repository: repository, currentUserID: currentID)
        }
        controller.onSelectConversation = { [weak controller] selected in
            guard let raw = repository.conversations().first(where: { $0.id.uuidString == selected.id }) else { return }
            repository.markConversationRead(raw.id)
            let currentAvatar = repository.currentUser.displayAvatarImage
            let chat = SocialChatViewController(participant: selected.participant, currentUserID: currentID.uuidString, messages: SocialCoreAdapters.messages(conversation: raw, currentUserID: currentID, currentUserAvatar: currentAvatar))
            chat.messageLoader = { completion in
                guard let conversation = repository.conversations().first(where: { $0.id == raw.id }) else {
                    completion(.failure(RepositoryMutationError.conversationNotFound))
                    return
                }
                completion(.success(SocialCoreAdapters.messages(conversation: conversation, currentUserID: currentID, currentUserAvatar: currentAvatar)))
            }
            chat.onPersistMessage = { message, completion in
                do {
                    try repository.appendMessage(SocialCoreAdapters.chatMessage(message), to: raw.id)
                    completion(.success(message))
                } catch {
                    completion(.failure(error))
                }
            }
            chat.onBack = { [weak chat] in chat?.navigationController?.popViewController(animated: true) }
            chat.onMore = { [weak chat] user in
                let sheet = VXActionSheetViewController(actions: [
                    VXSheetAction("Report") { if let id = UUID(uuidString: user.id) { chat?.vxOpenReport(targetUserID: id, sourceID: raw.id) } },
                    VXSheetAction("Block", style: .destructive) { if let id = UUID(uuidString: user.id) { LocalStore.shared.block(id); chat?.navigationController?.popViewController(animated: true) } }
                ])
                chat?.present(sheet, animated: true)
            }
            controller?.navigationController?.pushViewController(chat, animated: true)
        }
        controller.onBalance = { [weak controller] in controller?.navigationController?.pushViewController(RechargeViewController(), animated: true) }
        return controller
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard isGuest, let index = viewControllers?.firstIndex(of: viewController), index >= 1 else { return true }
        onGuestRestriction?(); return false
    }
}
