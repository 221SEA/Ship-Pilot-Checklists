//
//  SceneDelegate.swift
//  Ship Pilot Checklists
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
      _ scene: UIScene,
      willConnectTo session: UISceneSession,
      options connectionOptions: UIScene.ConnectionOptions
    ) {
        // 1) Grab the scene
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // 2) Create our window
        let window = UIWindow(windowScene: windowScene)

        // 3) Paint the window background
        window.backgroundColor = ThemeManager.backgroundColor(for: window.traitCollection)

        // 4) Build our nav stack
        let mainVC = MainViewController()
        let nav = UINavigationController(rootViewController: mainVC)

        // 5) Configure an opaque nav-bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = ThemeManager.navBarColor(for: window.traitCollection)
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
          .foregroundColor: ThemeManager.navBarForegroundColor(for: window.traitCollection)
        ]

        nav.navigationBar.standardAppearance = appearance
        nav.navigationBar.scrollEdgeAppearance  = appearance
        nav.navigationBar.compactAppearance      = appearance
        nav.navigationBar.compactScrollEdgeAppearance = appearance
        nav.navigationBar.tintColor = ThemeManager.navBarForegroundColor(for: window.traitCollection)

        // 6) Install and show
        window.rootViewController = nav
        window.makeKeyAndVisible()
        self.window = window

        // 7) Apply the rest of our theme
        ThemeManager.applyToCurrentWindow()
    }

}
    func sceneDidDisconnect(_ scene: UIScene) { }
    func sceneDidBecomeActive(_ scene: UIScene) { }
    func sceneWillResignActive(_ scene: UIScene) { }
    func sceneWillEnterForeground(_ scene: UIScene) { }
    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }

