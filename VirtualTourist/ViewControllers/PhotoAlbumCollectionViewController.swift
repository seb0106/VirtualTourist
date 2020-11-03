//*
// * Copyright (C) Schweizerische Bundesbahnen SBB, 2020.
//*

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoAlbumCollectionViewController: UIViewController , NSFetchedResultsControllerDelegate, MKMapViewDelegate{
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var CollectionViewFlowLayout: UICollectionViewFlowLayout!
    
    
    var pin: Pin!
    var fetchedResultController: NSFetchedResultsController<PhotoData>!
    var photos: [PhotoData] = [PhotoData]()
    var isPhotoStored = false
    
    let sectionInsets = UIEdgeInsets(top: 5.0, left: 20.0, bottom: 5.0, right: 20.0)
    let itemsPerRow: CGFloat = 3.0
    
    var photoCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        let annotation = MKPointAnnotation()
        annotation.coordinate.latitude = pin.latitutde
        annotation.coordinate.longitude = pin.longitude
        mapView.addAnnotation(annotation)
        collectionView.delegate = self
        collectionView.dataSource = self
        setUpFetchedResultsController()
        if isPhotoStored == false {
            setUpNewCollectionButton(isEnable: true)
            generatePhotos()
        } else {
            setUpNewCollectionButton(isEnable: false)
        }
    }
    
    func setUpNewCollectionButton(isEnable: Bool){
        newCollectionButton.isEnabled = isEnable
    }
    
    
    @IBAction func addNewCollection(_ sender: Any) {
        if let result = fetchedResultController.fetchedObjects {
            for photo in result {
                appDelegate.dataController.viewContext.delete(photo)
            }
        }
        generatePhotos()
    }
    
    func setUpFetchedResultsController(){
        let fetchRequest: NSFetchRequest<PhotoData> = PhotoData.fetchRequest()
        fetchRequest.sortDescriptors = []
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: appDelegate.dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultController.delegate = self
        do {
            try fetchedResultController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        if let data = fetchedResultController.fetchedObjects {
            if data.count == 0 {
                isPhotoStored = false
            } else {
                isPhotoStored = true
                photos = data
                photoCount = data.count
            }
        }
        
    }
    
    func showLoadFailure(message: String) {
        let alertVC = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        print(message)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertVC, animated: true, completion: nil)
    }
    
    func generatePhotos(){
        _ = FlickrClient.getPhotosByLocation(lat: pin.latitutde, lon: pin.longitude){
            (response, error) in
            if error != nil {
                self.showLoadFailure(message: error?.localizedDescription ?? "")
            } else {
                DataModel.photos = (response?.photos.photo)!
                if DataModel.photos.count == 0{
                    self.showLoadFailure(message: "There's no photo taken. Try again!")
                    return
                }
                self.collectionView.reloadData()
                self.collectionView.reloadInputViews()
            }
            
        }
    }

    func deletePhoto(indexOfPhoto: NSIndexPath) {
        let photo = fetchedResultController.object(at: indexOfPhoto as IndexPath)
        appDelegate.dataController.viewContext.delete(photo)
        try? appDelegate.dataController.viewContext.save()
    }
}
extension PhotoAlbumCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Collection item num: \(DataModel.photos.count)")
        if isPhotoStored {
            return fetchedResultController.fetchedObjects!.count
        } else {
            return DataModel.photos.count
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! PhotoCellView
        activityIndicator.startAnimating()
        cell.photoImageView.image = UIImage(named: "AppIcon")
        if isPhotoStored {
            let photo = fetchedResultController.object(at: indexPath)
            if let data = photo.image {
                cell.photoImageView.image = UIImage(data: data)
            }
        } else {
            let photo = DataModel.photos[indexPath.row]
            FlickrClient.downloadPhoto(farmId: photo.farm, serverId: photo.server, id: photo.id, secret: photo.secret) {
                data, error in
                guard let data = data else {
                    return
                }
                self.activityIndicator.hidesWhenStopped = true
                self.activityIndicator.stopAnimating()
                
                let image = UIImage(data: data)
                cell.photoImageView.image = image
                let p = PhotoData(context: self.appDelegate.dataController.viewContext)
                p.image = data
                p.pin = self.pin
                try? self.appDelegate.dataController.viewContext.save()
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deleteItems(at: [indexPath])
        deletePhoto(indexOfPhoto: indexPath as NSIndexPath)
        collectionView.reloadData()
    }
}

extension PhotoAlbumCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding = sectionInsets.left * (itemsPerRow + 1)
        let cellWidth = (view.frame.width - padding) / itemsPerRow
        return CGSize(width: cellWidth, height: cellWidth)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}
