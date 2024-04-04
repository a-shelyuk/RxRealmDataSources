//
//  RxRealm extensions
//
//  Copyright (c) 2016 RxSwiftCommunity. All rights reserved.
//  Check the LICENSE file for details
//

import Foundation

import RealmSwift
import RxSwift
import RxCocoa
import RxRealm
import UIKit

public typealias CollectionCellFactory<E: Object> = (RxCollectionViewRealmDataSource<E>, UICollectionView, IndexPath, E) -> UICollectionViewCell
public typealias CollectionCellConfig<E: Object, CellType: UICollectionViewCell> = (CellType, IndexPath, E) -> Void

open class RxCollectionViewRealmDataSource <E: Object>: NSObject, UICollectionViewDataSource {
    private var items: AnyRealmCollection<E>?

    // MARK: - Configuration

    public var collectionView: UICollectionView?
    public var animated = true

    // MARK: - Init
    public let cellIdentifier: String
    public let cellFactory: CollectionCellFactory<E>

    public init(cellIdentifier: String, cellFactory: @escaping CollectionCellFactory<E>) {
        self.cellIdentifier = cellIdentifier
        self.cellFactory = cellFactory
    }

    public init<CellType>(cellIdentifier: String, cellType: CellType.Type, cellConfig: @escaping CollectionCellConfig<E, CellType>) where CellType: UICollectionViewCell {
        self.cellIdentifier = cellIdentifier
        self.cellFactory = {ds, cv, ip, model in
            let cell = cv.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: ip) as! CellType
            cellConfig(cell, ip, model)
            return cell
        }
    }

    public init<CellType>(cellClass: CellType.Type, cellConfig: @escaping CollectionCellConfig<E, CellType>) where CellType: UICollectionViewCell, CellType: ReusableView {
        self.cellIdentifier = cellClass.reuseIdentifier
        self.cellFactory = { ds, cv, ip, model in
            let cell: CellType = cv.dequeueReusableCell(forIndexPath: ip)
            cellConfig(cell, ip, model)

            return cell
        }
    }

    var headerViewClass: AnyClass? {
        didSet { collectionView?.register(headerViewClass, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SectionHeader") }
    }

    var headerViewNib: UINib? {
        didSet { collectionView?.register(headerViewNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SectionHeader") }
    }

    // MARK: - Data access
    public func model(at indexPath: IndexPath) -> E {
        return items![indexPath.row]
    }

    // MARK: - UICollectionViewDataSource protocol
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items?.count ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return cellFactory(self, collectionView, indexPath, items![indexPath.row])
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let view: UICollectionReusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionHeader", for: indexPath)
            return view
        } else {
            fatalError()
        }
    }

    // MARK: - Applying changeset to the collection view
    private let fromRow = {(row: Int) in return IndexPath(row: row, section: 0)}

    func applyChanges(items: AnyRealmCollection<E>, changes: RealmChangeset?) {
        if self.items == nil {
            self.items = items
        }

        guard let collectionView = collectionView else {
            fatalError("You have to bind a collection view to the data source.")
        }

        guard animated else {
            collectionView.reloadData()
            return
        }

        guard let changes = changes else {
            collectionView.reloadData()
            return
        }

        let lastItemCount = collectionView.numberOfItems(inSection: 0)
        guard items.count == lastItemCount + changes.inserted.count - changes.deleted.count else {
            collectionView.reloadData()
            return
        }

        collectionView.performBatchUpdates({[unowned self] in
            collectionView.deleteItems(at: changes.deleted.map(self.fromRow))
            collectionView.reloadItems(at: changes.updated.map(self.fromRow))
            collectionView.insertItems(at: changes.inserted.map(self.fromRow))
        }, completion: nil)
    }
}
