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
    var fetchedResultController: NSFetchedResultsController<Pin>!
    var photos: [Photo] = [Photo]()
    var isPhotoStored = false
    
    var photoCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        let annotation = MKPointAnnotation()
        annotation.coordinate.latitude = pin.latitutde
        annotation.coordinate.longitude = pin.longitude
        mapView.addAnnotation(annotation)
      
        setUpFetchedResultsController()
        if isPhotoStored == false {
            generatePhotos()
        }
    }
    
    
    
    func setUpFetchedResultsController(){
        
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
    //var pin: Pin!
    
    
}
