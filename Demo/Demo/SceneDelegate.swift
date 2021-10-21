//
//  SceneDelegate.swift
//  Demo
//
//  Created by Andreas Verhoeven on 16/05/2021.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let windowScene = (scene as? UIWindowScene) else { return }
		window = UIWindow(windowScene: windowScene)
		guard let window = window else {return}

		window.makeKeyAndVisible()
		window.rootViewController = UINavigationController(rootViewController: ViewController())
	}
}

