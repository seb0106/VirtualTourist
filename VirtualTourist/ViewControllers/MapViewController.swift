//*
// * Copyright (C) Schweizerische Bundesbahnen SBB, 2020.
//*

import UIKit
import MapKit
import Foundation
import CoreData

class MapViewController: UIViewController, UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var centerPosition = CLLocationCoordinate2D()
    var zoomRange = MKCoordinateSpan()
   // var dataController : DataController!
    var fetchedResultsController : NSFetchedResultsController<Pin>!
    
    var mapPin: MKPointAnnotation?
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        let longPressed = UILongPressGestureRecognizer(target: self, action: #selector(handleTap(gestureRegonizer:)))
        longPressed.delegate = self
        longPressed.numberOfTapsRequired = 0
        longPressed.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressed)
        appDelegate.dataController.load()
        setUpFetchedResultsController()
        setUpPins()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveMapSetting()
    }
    
    @objc func handleTap(gestureRegonizer: UILongPressGestureRecognizer){
        if gestureRegonizer.state == .began{
            let location = gestureRegonizer.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            addPin(lat: coordinate.latitude, lon: coordinate.longitude)
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
            print("after saving pin:")
        }
        
    }
    
    func saveMapSetting(){
        UserDefaults.standard.set(centerPosition.latitude, forKey: "CenterPosLat")
        UserDefaults.standard.set(centerPosition.longitude, forKey: "CenterPosLon")
        UserDefaults.standard.set(zoomRange.latitudeDelta, forKey: "ZoomRangeLat")
        UserDefaults.standard.set(zoomRange.longitudeDelta, forKey: "ZoomRangeLon")
        UserDefaults.standard.synchronize()
    }
    
    func addPin(lat: Double, lon: Double){
        let pin = Pin(context: appDelegate.dataController.viewContext)
        pin.latitutde = lat
        pin.longitude = lon
        try? self.appDelegate.dataController.viewContext.save()
        setUpFetchedResultsController()
    }
    
    func setUpPins() {
        var annotiations = [MKPointAnnotation]()
        if let pins = fetchedResultsController.fetchedObjects {
            for pin in pins as [Pin] {
                let annotation = MKPointAnnotation()
                annotation.coordinate.latitude = pin.latitutde
                annotation.coordinate.longitude = pin.longitude
                annotiations.append(annotation)
            }
            mapView.addAnnotations(annotiations)
        }
        
    }
        
        func setUpFetchedResultsController(){
            let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
            fetchRequest.sortDescriptors = []
            fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: appDelegate.dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsController.delegate = self
            do{
                try fetchedResultsController.performFetch()
            }
            catch{
                print("There was a problem with fetching: \(error.localizedDescription)")
            }
            
        }
    }
extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "PinAnnotationIdentifier"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .blue
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
       let collectionVC = storyboard?.instantiateViewController(identifier: "PhotoAlbumCollectionViewController") as! PhotoAlbumCollectionViewController
            print("didSelect", collectionVC)
       // collectionVC.appDelegate.dataController = appDelegate.dataController
        if let pin = searchPinData(lat: (view.annotation?.coordinate.latitude)!, lon: (view.annotation?.coordinate.longitude)!) {
            collectionVC.pin = pin
        } else {
            print("Cannot access pin")
        }
        mapView.deselectAnnotation(view.annotation, animated: true)
        navigationController?.pushViewController(collectionVC, animated: true)
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView{
            print("didSelect")
        }
    }
    
    func searchPinData(lat: Double, lon: Double) -> Pin? {
        let latToCompare = NSNumber(value: lat)
        let lonToCompare = NSNumber(value: lon)
        try? self.appDelegate.dataController.viewContext.save()
        if let pins = fetchedResultsController.fetchedObjects {
            for pin in pins {
                let latNumber = NSNumber(value: pin.latitutde)
                let lonNumber = NSNumber(value: pin.longitude)
                if latToCompare == latNumber && lonToCompare == lonNumber {
                    return pin
                }
            }
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        centerPosition = mapView.centerCoordinate
        zoomRange = mapView.region.span
    }
}


