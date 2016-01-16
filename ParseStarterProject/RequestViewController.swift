//
//  RrequestViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Иван Магда on 16.01.16.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import MapKit
import Parse

class RequestViewController: UIViewController {
    //--------------------------------------
    // MARK: - Properties
    //--------------------------------------
    
    @IBOutlet weak var mapView: MKMapView!
    
    var requestLocation: CLLocationCoordinate2D!
    var requestUsername: String!
    
    //--------------------------------------
    // MARK: - View Life Cycle
    //--------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView.setRegion(MKCoordinateRegion(center: requestLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)), animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = requestLocation
        annotation.title = requestUsername
        mapView.addAnnotation(annotation)
    }
    
    //--------------------------------------
    // MARK: - Actions
    //--------------------------------------
    
    @IBAction func pickUpRider(sender: AnyObject) {
        RiderRequest.respondForRiderRequest(riderUsername: requestUsername, driverUsername: PFUser.currentUser()!.username!) { (success, error) in
            if success {
                CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: self.requestLocation.latitude, longitude: self.requestLocation.longitude), completionHandler: { (placemarks, error) in
                    if let error = error {
                        print(error.localizedDescription)
                    } else if let placemarks = placemarks where placemarks.count > 0 {
                        let placemark = placemarks[0]
                        
                        let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                        mapItem.name = self.requestUsername
                        
                        mapItem.openInMapsWithLaunchOptions([MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
                    }
                })
            } else {
                print(error?.localizedDescription)
            }
        }
    }
}
