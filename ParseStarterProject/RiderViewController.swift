//
//  RiderViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Иван Магда on 16.01.16.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit

class RiderViewController: UIViewController {
    //--------------------------------------
    // MARK: - Properties
    //--------------------------------------
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var callUberButton: UIButton!
    
    private var locationManager: CLLocationManager!
    private var previousLocation: CLLocationCoordinate2D?
    
    private var isRiderRequestActive = false
    
    //--------------------------------------
    // MARK: - View Life Cycle
    //--------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        instantiateLocationManager()
    }
    
    //--------------------------------------
    // MARK: - Private -
    //--------------------------------------
    
    private func instantiateLocationManager() {
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    private func displayAlert(title title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //--------------------------------------
    // MARK: Rider requests
    //--------------------------------------
    
    private func cancelAnUberForUser(user: PFUser) {
        let query = PFQuery(className: RiderRequestClassName)
        query.whereKey(RiderRequest.Keys.username.rawValue, equalTo: user.username!)
        
        query.findObjectsInBackgroundWithBlock() { (objects, error) in
            if let _ = error {
                self.displayAlert(title: "Could't cancel Uber", message: "Please try again later")
            } else if let request = objects as? [RiderRequest] {
                assert(request.count == 1)
                
                request[0].deleteInBackgroundWithBlock() { (success, error) in
                    if success {
                        self.isRiderRequestActive = false
                        
                        self.displayAlert(title: "Success", message: "Your Uber is canceled")
                        self.callUberButton.setTitle("Call an Uber", forState: .Normal)
                    } else {
                        print(error!.localizedDescription)
                    }
                }
            }
        }
    }
    
    private func requestAnUberForUser(user: PFUser) {
        if let coordinate = self.previousLocation {
            let riderRequest = RiderRequest()
            riderRequest.username = user.username!
            riderRequest.location = PFGeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            riderRequest.saveInBackgroundWithBlock() { (success, error) in
                if let error = error {
                    self.displayAlert(title: "Could not call Uber", message: error.localizedDescription)
                } else {
                    self.isRiderRequestActive = true
                    
                    self.displayAlert(title: "Success", message: "Your Uber is in progress")
                    self.callUberButton.setTitle("Cancel Uber", forState: .Normal)
                }
            }
        } else {
            displayAlert(title: "Could not call Uber", message: "Could not update your current location. Please, try again later.")
        }
        
    }
    
    //--------------------------------------
    // MARK: - Actions
    //--------------------------------------
    
    @IBAction func logOut(sender: AnyObject) {
        PFUser.logOutInBackgroundWithBlock() { error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }

    @IBAction func callAnUber(sender: AnyObject) {
        guard let user = PFUser.currentUser() else {
            return
        }
        
        if isRiderRequestActive {
            cancelAnUberForUser(user)
        } else {
            requestAnUberForUser(user)
        }
    }
}

//--------------------------------------
// MARK: - CLLocationManagerDelegate -
//--------------------------------------

extension RiderViewController: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordinate = manager.location?.coordinate {
            self.mapView.setRegion(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)), animated: true)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = NSLocalizedString("Your location", comment: "")
            
            if self.previousLocation == nil {
                self.previousLocation = coordinate
                mapView.addAnnotation(annotation)
            } else if self.previousLocation!.latitude != coordinate.latitude &&
                self.previousLocation!.longitude != coordinate.longitude {
                    mapView.removeAnnotations(mapView.annotations)
                    mapView.addAnnotation(annotation)
            }
            
            self.previousLocation = coordinate
        }
    }
}

//--------------------------------------
// MARK: - MKMapViewDelegate -
//--------------------------------------

extension RiderViewController: MKMapViewDelegate {
    
}
