//
//  ViewController.swift
//  Demo
//
//  Created by Andreas Verhoeven on 16/05/2021.
//

import UIKit

class ViewController: UIViewController {
	let stackedItemsView = StackedItemsView<UIColor, UICollectionViewCell>()

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .systemBackground

		stackedItemsView.items = [.red, .blue, .brown, .green, .orange, .purple, .yellow, .gray, .cyan, .magenta]
		stackedItemsView.configureItemHandler = { item, cell in
			cell.contentView.backgroundColor = item
		}
		stackedItemsView.selectionHandler = { [weak self] item in
			let controller = UIAlertController(title: item.description, message: nil, preferredStyle: .alert)
			controller.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
			self?.present(controller, animated: true)
		}
		view.addSubview(stackedItemsView)
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		stackedItemsView.frame = CGRect(origin: .zero, size: view.bounds.size)
	}
}
