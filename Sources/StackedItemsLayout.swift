//
//  StackedItemsLayout.swift
//	StackedItemsCarousel
//
//  Created by Andreas Verhoeven on 21/10/2021.
//

import UIKit

/// A UICollectionViewLayout that shows a stack of items
/// that the user can swipe thru. The swipe animations
/// are completely driven by scrolling the collection view.
public class StackedItemsLayout: UICollectionViewLayout {
	/// The size of each item
	public var itemSize = CGSize(width: 200, height: 260) {
		didSet {
			guard itemSize != oldValue else { return }
			invalidateLayout()
		}
	}

	/// the horizontal alignment of the complete stack of items
	public var horizontalAlignment: HorizontalAlignment = .middle {
		didSet {
			guard horizontalAlignment != oldValue else { return }
			invalidateLayout()
		}
	}

	/// the vertical alignment of the complete stack of items
	public var verticalAlignment: VerticalAlignment = .middle {
		didSet {
			guard verticalAlignment != oldValue else { return }
			invalidateLayout()
		}
	}

	public enum HorizontalAlignment {
		case leading
		case middle
		case trailing

		fileprivate func xPosition(itemSize: CGSize, in collectionView: UICollectionView, offset: CGFloat) -> CGFloat {
			let width = collectionView.bounds.inset(by: collectionView.adjustedContentInset).width
			switch self {
				case .leading: return offset + collectionView.adjustedContentInset.left
				case .middle: return width * 0.5 - itemSize.width * 0.5 + collectionView.adjustedContentInset.left
				case .trailing: return width - offset - collectionView.adjustedContentInset.right - itemSize.width
			}
		}
	}

	public enum VerticalAlignment {
		case top
		case middle
		case bottom

		fileprivate func yPosition(itemSize: CGSize, in collectionView: UICollectionView) -> CGFloat {
			let height = collectionView.bounds.inset(by: collectionView.adjustedContentInset).height
			switch self {
				case .top: return collectionView.adjustedContentInset.top
				case .middle: return height * 0.5 - itemSize.height * 0.5 + collectionView.adjustedContentInset.top
				case .bottom: return height - collectionView.adjustedContentInset.bottom - itemSize.height
			}
		}
	}

	/// the index of the item that is currently focussed and thus
	/// on top or in-flight of an "animation"
	public private(set) var currentlyFocusedItemIndex = 0

	/// the intrinsic content size for this layout
	public var intrinsicContentSize: CGSize {
		return CGSize(width: itemSize.width + totalEffectiveHorizontalOffset * 2, height: itemSize.height)
	}

	// MARK: - Private

	/// Our cached item
	private var items = [UICollectionViewLayoutAttributes]()
	private let perItemRotationRadians = CGFloat(2 * CGFloat.pi / 180)
	private let perItemScale = CGFloat(0.9)
	private let horizontalOffsets: [CGFloat] = [20, 14.5, 10, 9, 5]
	private lazy var totalEffectiveHorizontalOffset = ceil(horizontalOffsets.reduce(CGFloat(0), +) * pow(perItemScale, CGFloat(horizontalOffsets.count - 1)) - horizontalOffsets.last!)

	/// Returns the horizontal offset for progress ("offset") for an item
	private func horizontalOffsetForProgress(_ offset: CGFloat) -> CGFloat {
		let index = Int(offset)
		let progress = offset - CGFloat(index)

		var value = horizontalOffsets.prefix(min(horizontalOffsets.count, max(0, index))).reduce(CGFloat(0), +)
		if index >= 0 && index < horizontalOffsets.count {
			value += horizontalOffsets[index] * progress
		}

		return value
	}

	/// Structure that models a translate, rotate and scale transform
	private struct ItemTransform {
		var horizontalOffset: CGFloat
		var rotation: CGFloat
		var scale: CGFloat

		var transform3D: CATransform3D {
			var transform = CATransform3DIdentity
			transform = CATransform3DTranslate(transform, horizontalOffset, 0, 0)
			transform = CATransform3DRotate(transform, rotation, 0, 0, 1)
			transform = CATransform3DScale(transform, 1 + scale, 1 + scale, 1)
			return transform
		}

		func multiplyPositions(by factor: CGFloat) -> Self {
			return Self(horizontalOffset: horizontalOffset * factor,
						rotation: rotation * factor,
						scale: scale)
		}

		func add(_ other: Self) -> Self {
			return Self(horizontalOffset: horizontalOffset + other.horizontalOffset,
						rotation: rotation + other.rotation,
						scale: scale + other.scale)
		}

		func subtract(_ other: Self) -> Self {
			return Self(horizontalOffset: horizontalOffset - other.horizontalOffset,
						rotation: rotation - other.rotation,
						scale: scale - other.scale)
		}

		func linearScrubbed(_ progress: CGFloat) -> Self {
			return Self(
				horizontalOffset: horizontalOffset * progress,
				rotation: rotation * progress,
				scale: scale * progress)
		}

		func easeInOutScrubbed(_ progress: CGFloat) -> Self {
			return linearScrubbed(progress * progress * (3 - 2 * progress))
		}
	}


	// MARK: - UICollectionView
	public override func prepare() {
		super.prepare()

		guard let collectionView = collectionView else { return }
		let numberOfItems = collectionView.dataSource?.collectionView(collectionView, numberOfItemsInSection: 0) ?? 0
		let size = collectionView.bounds.size
		let pageWidth = size.width

		// we need to have items and a width
		guard numberOfItems > 0, pageWidth > 0 else {
			items = []
			return
		}

		/// calculates the contentOffset for an item at a given index
		func contentOffsetForIndex(_ index: Int) -> CGFloat {
			return pageWidth * CGFloat(index)
		}

		/// calculates the ItemTransform for an item at the given relative index and swipe-to-next-item-progress
		func itemTransformForItem(index: Int, progress: CGFloat, isLeading: Bool) -> ItemTransform {
			let multiplier = CGFloat(isLeading ? -1 : 1)
			let pageProgress = contentOffsetForIndex(index)/pageWidth - progress * multiplier
			let horizontalOffset = horizontalOffsetForProgress(pageProgress) * multiplier
			let rotation = perItemRotationRadians * pageProgress * multiplier
			let scale = pow(0.9, pageProgress)
			return ItemTransform(horizontalOffset: horizontalOffset, rotation: rotation, scale: scale - 1)
		}

		let offset = collectionView.contentOffset.x
		let index = max(0, min(numberOfItems - 1, Int(offset / pageWidth)))
		let roundedIndex = max(0, min(numberOfItems - 1, Int(round(offset / pageWidth))))
		
		let canGoForward = currentlyFocusedItemIndex < numberOfItems - 1
		let canGoBackwards = currentlyFocusedItemIndex > 0

		/// we only change the `currentlyFocusedItemIndex` when we
		/// actually have seen the next/previous item fully, because
		/// if we're swiping backwards we move past a boundary,
		/// but it's still part of the current items animation
		if canGoForward && index > currentlyFocusedItemIndex  {
			currentlyFocusedItemIndex = index
		} else if canGoBackwards && offset <= contentOffsetForIndex(currentlyFocusedItemIndex - 1) {
			currentlyFocusedItemIndex = roundedIndex
		}

		let progressFromFocusedItem = (offset - contentOffsetForIndex(currentlyFocusedItemIndex)) / pageWidth
		let isMovingToLeadingStack = (progressFromFocusedItem > 0)
		let isMovingToTrailingStack = (progressFromFocusedItem < 0)
		let shouldRubberBand = (canGoForward == false && isMovingToLeadingStack) || (canGoBackwards == false && isMovingToTrailingStack)

		/// cache all items
		items = (0..<numberOfItems).map { index in
			let item = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: index, section: 0))

			/// the frame of each item is the same, adjusted for the current content offset so our items do not scroll
			item.frame = CGRect(
				x: collectionView.contentOffset.x + horizontalAlignment.xPosition(itemSize: itemSize, in: collectionView, offset: totalEffectiveHorizontalOffset),
				y: collectionView.contentOffset.y + verticalAlignment.yPosition(itemSize: itemSize, in: collectionView),
				width: itemSize.width,
				height: itemSize.height)

			// we lay out our items relative to the current index:
			//	- the currently focused item is on top
			//  - items before it are on its leading side
			//  - items after it are on its trailing side
			let relativeIndex = abs(index - currentlyFocusedItemIndex)

			if index == currentlyFocusedItemIndex && shouldRubberBand == false  {
				// the top item that needs to animate to disappear behind the previous/next item
				// depending on the direction we are scrolling. Our animation exist of two parts:
				//	- the first part, where we move from the top of the stack to the side
				//  - the second part, where we move from the side of the stack to behind the new "top of stack"

				let factor = CGFloat(isMovingToLeadingStack == true ? -1 : 1)
				let side = ItemTransform(horizontalOffset: itemSize.width * 0.77,
										 rotation: 22.5 * .pi / 180,
										 scale: -0.5).multiplyPositions(by: factor)

				let progress = abs(progressFromFocusedItem)
				if progress < 0.5 {
					// first part of the animation, we are still on top and are moving the item to the side
					item.zIndex = 0
					item.transform3D = side.easeInOutScrubbed(progress / 0.5).transform3D
				} else {
					// second part of the animation, we are moved to the side and are moving back and are now
					// behind the next item, so we need to make sure that this item zIndex is smaller than the next
					// item: -3 does this, because the next item starts at zIndex = -2
					item.zIndex = -3

					// also interpolate from the side position to our new final position
					let final = itemTransformForItem(index: 1, progress: 0, isLeading: isMovingToLeadingStack)
					let difference = final.subtract(side)
					let interpolated = difference.easeInOutScrubbed((progress - 0.5) * 2)
					item.transform3D = side.add(interpolated).transform3D
				}
				return item
			} else if relativeIndex <= horizontalOffsets.count {
				// items that are next to the top item on the stack:
				// we need to change the zIndex depending if we're scrolling that stacks next item
				// into view: that stack gets to be on top of the other (but still behind the top item)
				let isPartOfLeadingStack = index < currentlyFocusedItemIndex
				if isMovingToLeadingStack != isPartOfLeadingStack {
					item.zIndex = -2 * relativeIndex
				} else {
					item.zIndex = -horizontalOffsets.count - 2 * relativeIndex
				}

				// calculate the transform for our items on the stacks
				item.transform3D = itemTransformForItem(index: relativeIndex, progress: progressFromFocusedItem, isLeading: isPartOfLeadingStack).transform3D

				// we animate in the alpha of the final item of the stack, so that it appears nicely
				if relativeIndex == horizontalOffsets.count {
					item.alpha = abs(progressFromFocusedItem)
				} else {
					item.alpha = 1
				}

			} else {
				// items not on the stack are hidden
				item.isHidden = true
			}
			return item
		}
	}

	public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
		return true
	}

	public override var collectionViewContentSize: CGSize {
		guard let collectionView = collectionView else { return .zero }
		let size = collectionView.bounds.inset(by: collectionView.adjustedContentInset)
		return CGSize(width: collectionView.bounds.width * CGFloat(items.count), height: size.height)
	}

	public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		return items.filter { $0.frame.intersects(rect) }
	}

	public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		return items[indexPath.item]
	}
}
