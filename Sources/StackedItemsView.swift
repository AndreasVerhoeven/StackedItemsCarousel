//
//  StackedItemsView.swift
//  StackedItemsCarousel
//
//  Created by Andreas Verhoeven on 21/10/2021.
//

import UIKit

/// A view that provides a stacked of scrollable items by wrapping a UICollectionView with a `StackedItemsLayout`
public class StackedItemsView<ItemType: Equatable, CellType: UICollectionViewCell>: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UIContextMenuInteractionDelegate, UIDragInteractionDelegate {

	public let collectionView = UICollectionView(frame: .zero, collectionViewLayout: StackedItemsLayout())
	private var lastIndexOfContextMenu: Int?

	/// this will be called to configure each cell
	public var configureItemHandler: ConfigureItemHandler?
	public typealias ConfigureItemHandler = (ItemType, CellType) -> Void

	/// this will be called when an item is selected
	public var selectionHandler: SelectionHandler?
	public typealias SelectionHandler = (ItemType, Int) -> Void

	/// this will be called when an item is dragged
	public var dragItemsProvider: DragItemsProvider?
	public typealias DragItemsProvider = (ItemType, Int, UIDragSession) -> [UIDragItem]

	/// this will be called when the context menu is needed for an item
	public var contextMenuConfigurationProvider: ContextMenuConfigurationProvider?
	public typealias ContextMenuConfigurationProvider = (ItemType, Int) -> UIContextMenuConfiguration?

	/// this will be called when the preview of a context menu is committed
	public var commitContextMenuPreviewHandler: CommitContextMenuPreviewHandler?
	public typealias CommitContextMenuPreviewHandler = (UIContextMenuConfiguration, UIContextMenuInteractionCommitAnimating) -> Void

	/// The items this view displays
	public var items = [ItemType]() {
		didSet {
			guard items != oldValue else { return }
			collectionView.reloadData()
			scrollToItem(at: 0, animated: false)
		}
	}

	/// the horizontal alignment of the stack inside this view
	public var horizontalAlignment: StackedItemsLayout.HorizontalAlignment {
		get { stackedItemsLayout.horizontalAlignment }
		set { stackedItemsLayout.horizontalAlignment = newValue }
	}

	/// the verticalAlignment alignment of the stack inside this view
	public var verticalAlignment: StackedItemsLayout.VerticalAlignment {
		get { stackedItemsLayout.verticalAlignment }
		set { stackedItemsLayout.verticalAlignment = newValue }
	}

	// the size of each item in the stack
	public var itemSize: CGSize {
		get {
			return stackedItemsLayout.itemSize
		}
		set {
			guard itemSize != newValue else { return }
			stackedItemsLayout.itemSize = newValue
			invalidateIntrinsicContentSize()
		}
	}

	/// the corner radius for each item
	public var cornerRadius = CGFloat(20) {
		didSet {
			guard cornerRadius != oldValue else { return }
			collectionView.reloadData()
		}
	}

	/// the index of the item that is currently focused and on the top of the stack
	public var currentlyFocusedItemIndex: Int {
		return stackedItemsLayout.currentlyFocusedItemIndex
	}

	/// the pan gesture recognizer for the collection view
	public var panGestureRecognizer: UIPanGestureRecognizer {
		collectionView.panGestureRecognizer
	}

	/// scrolls to a specific item by making it top of the stack
	public func scrollToItem(at index: Int, animated: Bool) {
		let xOffset = collectionView.bounds.width * CGFloat(index)
		let contentOffset = CGPoint(x: -collectionView.adjustedContentInset.left + xOffset, y: -collectionView.adjustedContentInset.top)
		collectionView.setContentOffset(contentOffset, animated: animated)
		if animated == false {
			collectionView.setNeedsLayout()
			collectionView.layoutIfNeeded()
		}
	}

	/// returns the cell at the given index, if visible
	public func cell(at index: Int) -> CellType? {
		return collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? CellType
	}

	// MARK: UICollectionViewDataSource
	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return items.count
	}

	public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)

		cell.contentView.clipsToBounds = true
		cell.contentView.layer.cornerRadius = cornerRadius
		cell.contentView.layer.allowsEdgeAntialiasing = true

		if #available(iOS 13, *) {
			cell.contentView.layer.cornerCurve = .continuous
		}

		cell.layer.allowsEdgeAntialiasing = true
		cell.layer.shadowRadius = 4
		cell.layer.shadowOpacity = 0.15
		cell.layer.shadowOffset = .zero
		cell.layer.shadowPath = UIBezierPath(roundedRect:CGRect(origin: .zero, size:  stackedItemsLayout.itemSize), cornerRadius: cornerRadius).cgPath
		configureItemHandler?(items[indexPath.row], cell as! CellType)

		return cell
	}

	// MARK: UICollectionViewDelegate
	public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if indexPath.row == currentlyFocusedItemIndex {
			collectionView.deselectItem(at: indexPath, animated: true)
			selectionHandler?(items[indexPath.row], indexPath.row)
		} else if indexPath.row < currentlyFocusedItemIndex {
			return scrollToItem(at: currentlyFocusedItemIndex - 1, animated: true)
		} else {
			return scrollToItem(at: currentlyFocusedItemIndex + 1, animated: true)
		}
	}

	// MARK: - UIContextMenuInteractionDelegate
	public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
		guard collectionView.indexPathForItem(at: collectionView.convert(location, from: self))?.row == currentlyFocusedItemIndex else { return nil }

		lastIndexOfContextMenu = currentlyFocusedItemIndex
		return contextMenuConfigurationProvider?(items[currentlyFocusedItemIndex], currentlyFocusedItemIndex)
	}

	public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
		return targetedDragPreviewForCurrentCell
	}

	public func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
		return targetedDragPreviewForCurrentCell
	}

	public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
		commitContextMenuPreviewHandler?(configuration, animator)
	}

	// MARK: - UIDragInteractionDelegate
	public func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
		guard collectionView.indexPathForItem(at: session.location(in: collectionView))?.row == currentlyFocusedItemIndex else { return [] }
		return dragItemsProvider?(items[currentlyFocusedItemIndex], currentlyFocusedItemIndex, session) ?? []
	}

	public func dragInteraction(_ interaction: UIDragInteraction, itemsForAddingTo session: UIDragSession, withTouchAt point: CGPoint) -> [UIDragItem] {
		guard collectionView.indexPathForItem(at: collectionView.convert(point, from: self))?.row == currentlyFocusedItemIndex else { return [] }
		return dragItemsProvider?(items[currentlyFocusedItemIndex], currentlyFocusedItemIndex, session) ?? []
	}

	public func dragInteraction(_ interaction: UIDragInteraction, previewForLifting item: UIDragItem, session: UIDragSession) -> UITargetedDragPreview? {
		return targetedDragPreviewForCurrentCell
	}

	public func dragInteraction(_ interaction: UIDragInteraction, previewForCancelling item: UIDragItem, withDefault defaultPreview: UITargetedDragPreview) -> UITargetedDragPreview? {
		return targetedDragPreviewForCurrentCell
	}

	public func dragInteraction(_ interaction: UIDragInteraction, item: UIDragItem, willAnimateCancelWith animator: UIDragAnimating) {
		animator.addCompletion { _ in
			self.stackedItemsLayout.invalidateLayout()
		}
	}

	// MARK: - UIScrollViewDelegate

	public func scrollViewDidScroll(_ scrollView: UIScrollView) {
		if scrollView.isTracking == true {
			// WORKAROUND(iOS 13, *) This is a workaround for UIContextMenuInteraction
			// replacing our cell with a fake view when we pan a little bit:
			// the fake view doesn't animate correctly, so it looks weird.
			// By removing the fake view, that interaction ends immediately.
			for subview in scrollView.subviews {
				guard subview is UICollectionViewCell == false else { continue }
				guard NSStringFromClass(subview.classForCoder).hasPrefix("_UI") else { continue }
				subview.removeFromSuperview()
			}
		}
	}

	// MARK: - Private
	private func setup() {
		collectionView.backgroundColor = nil
		collectionView.alwaysBounceHorizontal = true
		collectionView.clipsToBounds = false
		collectionView.isPagingEnabled = true
		collectionView.showsVerticalScrollIndicator = false
		collectionView.showsHorizontalScrollIndicator = false
		collectionView.dataSource = self
		collectionView.delegate = self
		collectionView.register(CellType.self, forCellWithReuseIdentifier: "Cell")
		addSubview(collectionView)

		addInteraction(UIContextMenuInteraction(delegate: self))
		addInteraction(UIDragInteraction(delegate: self))
	}

	private var stackedItemsLayout: StackedItemsLayout! {
		return collectionView.collectionViewLayout as? StackedItemsLayout
	}

	private var targetedDragPreviewForCurrentCell: UITargetedDragPreview? {
		guard let cell = cell(at: currentlyFocusedItemIndex) else { return nil }
		let parameters = UIDragPreviewParameters()
		parameters.visiblePath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: itemSize), cornerRadius: cornerRadius)
		return UITargetedDragPreview(view: cell, parameters: parameters)
	}

	// MARK: - UIView
	public override var intrinsicContentSize: CGSize {
		return stackedItemsLayout.intrinsicContentSize
	}

	public override func layoutSubviews() {
		super.layoutSubviews()
		collectionView.frame = CGRect(origin: .zero, size: bounds.size)
	}

	public override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}

	public required init?(coder: NSCoder) {
		super.init(coder: coder)
		setup()
	}
}
