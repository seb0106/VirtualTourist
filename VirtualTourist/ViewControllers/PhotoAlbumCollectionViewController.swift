//*
// * Copyright (C) Schweizerische Bundesbahnen SBB, 2020.
//*

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoAlbumCollectionViewController: UIViewController , NSFetchedResultsControllerDelegate, MKMapViewDelegate{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var CollectionViewFlowLayout: UICollectionViewFlowLayout!
    
    
    var pin: Pin!
    var dataController: DataController!
    var fetchedResultController: NSFetchedResultsController<PhotoData>!
    var photos: [PhotoData] = [PhotoData]()
    var isPhotoStored = false
    
    var photoCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        let annotation = MKPointAnnotation()
        annotation.coordinate.latitude = pin.latitutde
        annotation.coordinate.longitude = pin.longitude
        mapView.addAnnotation(annotation)
        dataController = DataController(modelName: "VirtualTourist")
        setUpFetchedResultsController()
        if isPhotoStored == false {
            generatePhotos()
        }
    }
    
    
    
    func setUpFetchedResultsController(){
        let fetchRequest: NSFetchRequest<PhotoData> = PhotoData.fetchRequest()
        fetchRequest.sortDescriptors = []
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
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
    
    func generatePhotos(){
        _ = FlickrClient.getPhotosByLocation(lat: pin.latitutde, lon: pin.longitude){
            response, error in
            if let error = error {
                print(error)
            } else {
                DataModel.photos = (response?.photos.photo)!
                if DataModel.photos.count == 0{
                    print("Theres no photo taken")
                    return
                }
                self.collectionView.reloadData()
                self.collectionView.reloadInputViews()
            }
            
        }
    }
    //var pin: Pin
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
                let image = UIImage(data: data)
                cell.photoImageView.image = image
                let p = PhotoData(context: self.dataController.viewContext)
                p.image = data
                p.pin = self.pin
                try? self.dataController.viewContext.save()
            }
        }
        return cell
    }
}
