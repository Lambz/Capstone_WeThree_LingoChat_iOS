//
//  LocationViewController.swift
//  Lingo Chat
//
//  Created by Chetan on 2020-08-22.
//  Copyright © 2020 Chetan. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class LocationViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var sendButton: UIBarButtonItem!
    
    @IBOutlet var longPressGesture: UILongPressGestureRecognizer!
    public var selectedLocation: CLLocationCoordinate2D!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        self.tabBarController?.tabBar.isHidden = true
        sendButton.title = NSLocalizedString("9As-mD-FEF.title", comment: "")
        sendButton.isEnabled = true
        if selectedLocation != nil {
            sendButton.isEnabled = false
            showLocation()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func setupViews() {
        mapView.delegate = self
        longPressGesture.addTarget(self, action: #selector(handleMapTap))
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832), span: span)
        mapView.setRegion(region, animated: true)
        mapView.showsUserLocation = true
        mapView.isZoomEnabled = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destVC = segue.destination as? ConversationViewController {
            destVC.latitude = selectedLocation.latitude
            destVC.longitude = selectedLocation.longitude
            selectedLocation = nil
        }
    }
    
    @IBAction func sendButtonTapped(_ sender: Any) {
        guard selectedLocation != nil else {
//            show alert
            return
        }
       
        performSegue(withIdentifier: "showConversationScreen", sender: self)
    }
}


extension LocationViewController: MKMapViewDelegate {
    @objc func handleMapTap(_ gestureRecognizer: UILongPressGestureRecognizer) {
        let location = gestureRecognizer.location(in: mapView)
        let coordinates = mapView.convert(location, toCoordinateFrom: mapView)
        selectedLocation = coordinates
        showLocation()
        
    }
    
    private func showLocation() {
        let annotation = MKPointAnnotation()
                annotation.coordinate = selectedLocation
                annotation.title = "Location"
        //        clear annotations
                let annotations = mapView.annotations
                mapView.removeAnnotations(annotations)
                
                mapView.addAnnotation(annotation)
    }
}


