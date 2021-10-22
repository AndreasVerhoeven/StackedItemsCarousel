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

		// configures our cells
		stackedItemsView.configureItemHandler = { item, cell in
			cell.contentView.backgroundColor = item
		}

		// handles selection
		stackedItemsView.selectionHandler = { [weak self] item, index in
			let controller = UIAlertController(title: item.description, message: nil, preferredStyle: .alert)
			controller.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
			self?.present(controller, animated: true)
		}

		// provides a context menu for our cells
		stackedItemsView.contextMenuConfigurationProvider = { item, index in
			return UIContextMenuConfiguration(identifier: nil) {
				let controller = UIViewController()
				controller.view.backgroundColor = item
				return controller
			} actionProvider: { _ in
				let items = [UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc"), handler: { _ in
					UIPasteboard.general.color = item
				})]
				return UIMenu(title: "", children: items)
			}
		}

		// commits the preview of our context menu
		stackedItemsView.commitContextMenuPreviewHandler = { [weak self] configuration, animator in
			animator.addAnimations {
				animator.previewViewController.map { self?.present($0, animated: true) }
			}
		}

		// provide drag items
		stackedItemsView.dragItemsProvider = { item, index in
			return [UIDragItem(itemProvider: NSItemProvider(object: item))]
		}

		view.addSubview(stackedItemsView)
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		stackedItemsView.frame = CGRect(origin: .zero, size: view.bounds.size)
	}
}
