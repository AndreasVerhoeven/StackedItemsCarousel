//
//  StackedItemsView.swift
//  StackedItemsCarousel
//
//  Created by Andreas Verhoeven on 21/10/2021.
//

import UIKit

/// A view that provides a stacked of scrollable items by wrapping a UICollectionView with a `StackedItemsLayout`
public class StackedItemsView<ItemType: Equatable, CellType: UICollectionViewCell>: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
	public let collectionView = UICollectionView(frame: .zero, collectionViewLayout: StackedItemsLayout())

	/// this will be called to configure each cell
	public var configureItemHandler: ConfigureItemHandler?
	public typealias ConfigureItemHandler = (ItemType, CellType) -> Void


	/// this will be called when an item is selected
	public var selectionHandler: SelectionHandler?
	public typealias SelectionHandler = (ItemType) -> Void

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

	/// the pan gesture recognizer for the collection view
	public var panGestureRecognizer: UIPanGestureRecognizer {
		collectionView.panGestureRecognizer
	}

	/// scrolls to a specific item by making it top of the stack
	public func scrollToItem(at index: Int, animated: Bool) {
		let xOffset = collectionView.bounds.width * CGFloat(index)
		let contentOffset = CGPoint(x: -collectionView.adjustedContentInset.left + xOffset, y: -collectionView.adjustedContentInset.top)
		collectionView.setContentOffset(contentOffset, animated: animated)
	}

	// MARK: UICollectionViewDataSource
	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return items.count
	}

	public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)

		cell.contentView.clipsToBounds = true
		cell.contentView.layer.cornerRadius = cornerRadius
		if #available(iOS 13, *) {
			cell.contentView.layer.cornerCurve = .continuous
		}

		cell.layer.shadowRadius = 4
		cell.layer.shadowOpacity = 0.15
		cell.layer.shadowOffset = .zero
		cell.layer.shadowPath = UIBezierPath(roundedRect:CGRect(origin: .zero, size:  stackedItemsLayout.itemSize), cornerRadius: cornerRadius).cgPath
		configureItemHandler?(items[indexPath.row], cell as! CellType)

		return cell
	}

	// MARK: UICollectionViewDelegate
	public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		collectionView.deselectItem(at: indexPath, animated: true)
		selectionHandler?(items[indexPath.row])
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
	}

	private var stackedItemsLayout: StackedItemsLayout! {
		return collectionView.collectionViewLayout as? StackedItemsLayout
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
