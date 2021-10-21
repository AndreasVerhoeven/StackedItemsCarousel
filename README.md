# StackedItemsCarousel
A carousel of stacked items (such as photos) as seen in iMessage



## What?

iMessage on iOS 15 shows multiple photos in a carousel of stacked items that the user can swipe thru. This is a reimplementation of that view.

## How to use?


### StackedItemsLayout

The carousel has been implemented as a custom `UICollectionViewLayout`: `StackedItemsLayout`. You can use this layout directly in a `UICollectionView` that uses paging:

```
let collectionView = UICollectionView(frame: .zero, collectionViewLayout: StackedItemsLayout())
collectionView.backgroundColor = nil
collectionView.alwaysBounceHorizontal = true
collectionView.clipsToBounds = false
collectionView.isPagingEnabled = true

//  configure the collection view as any other collection view 
```

 

### StackedItemsView

You can also use the convenience wrapper view, `StackedItemsView`. This is a generic view that takes an ItemType and CellType as generic parameters and handles the collection view for you:

```
let stackedItemsView = StackedItemsView<UIColor, YourSubclassOfUICollectionViewCell>()

stackedItemsView.items = [.red, .blue, .brown, .green, .orange, .purple, .yellow, .gray, .cyan, .magenta]
stackedItemsView.configureItemHandler = { item, cell in
	// configure your cell here - it already has some shadow and corner radius parameters set on
	// the cell itself.
}
stackedItemsView.selectionHandler = { [weak self] item in
	// handle item selection here
}
view.addSubview(stackedItemsView)
```
