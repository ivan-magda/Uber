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
    
    /// If user call for Uber and request is created for Parse API, but callback
    /// doesn't invoke eyet, then we are using this variable for determine can we
    /// create another request or need to wait for callback of the previous request.
    private var isRequesting = false
    
    private var driverIsOnTheWay = false
    
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
        guard let user = PFUser.currentUser() where isRequesting == false else {
            return
        }
        
        if isRiderRequestActive {
            RiderRequest.cancelAnUberForUser(user) { (success, error) in
                if success {
                    self.isRiderRequestActive = false
                    
                    self.displayAlert(title: "Success", message: "Your Uber is canceled")
                    self.callUberButton.setTitle("Call an Uber", forState: .Normal)
                } else {
                    self.displayAlert(title: "Could't cancel Uber", message: "Please try again later")
                }
            }
        } else {
            if let coordinate = self.previousLocation {
                RiderRequest.requestAnUberForUser(user, withLocationCoordinate: coordinate) { (success, error) in
                    if success {
                        self.isRiderRequestActive = true
                        
                        self.displayAlert(title: "Success", message: "Your Uber is in progress")
                        self.callUberButton.setTitle("Cancel Uber", forState: .Normal)
                    } else if let error = error {
                        self.displayAlert(title: "Could't call Uber", message: error.localizedDescription)
                    }
                }
            } else {
                displayAlert(title: "Could't call Uber", message: "Could't update your current location. Please, try again later.")
            }
        }
    }
}

//--------------------------------------
// MARK: - CLLocationManagerDelegate -
//--------------------------------------

extension RiderViewController: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordinate = manager.location?.coordinate {
            let query = PFQuery(className: RiderRequest.parseClassName())
            query.whereKey(RiderRequest.Keys.username.rawValue, equalTo: PFUser.currentUser()!.username!)
            query.whereKey(RiderRequest.Keys.driverResponded.rawValue, notEqualTo: "")
            
            query.findObjectsInBackgroundWithBlock() { (requests, error) in
                if let error = error {
                    print(error.localizedDescription)
                } else if let requests = requests as? [RiderRequest] where requests.count > 0 {
                    DriverLocation.getDriverLocationFromUsername(requests[0].driverResponded, block: { (location, error) in
                        if let error = error {
                            print(error.localizedDescription)
                        } else if let location = location {
                            let driverLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                            
                            let distanceInMeters = manager.location!.distanceFromLocation(driverLocation)
                            let distanceInKm = round((distanceInMeters / 1000.0) * 10.0) / 10.0
                            
                            self.callUberButton.setTitle("Driver is \(distanceInKm) the Way", forState: .Normal)
                            
                            self.driverIsOnTheWay = true
                            
                            self.updateMapViewWithCoordinates(riderCoordinate: coordinate, driverCoordinate: CLLocationCoordinate2DMake(location.latitude, location.longitude))
                        }
                    })
                } else {
                    self.driverIsOnTheWay = false
                    self.callUberButton.setTitle("Call an Uber", forState: .Normal)
                }
            }
            
            if driverIsOnTheWay == false {
                updateMapViewWithCoordinates(riderCoordinate: coordinate, driverCoordinate: nil)
            }
            
            self.previousLocation = coordinate
        }
    }
    
    private func updateMapViewWithCoordinates(riderCoordinate riderCoordinate: CLLocationCoordinate2D, driverCoordinate: CLLocationCoordinate2D?) {
        if let driverCoordinate = driverCoordinate {
            let latDelta = abs(riderCoordinate.latitude - driverCoordinate.latitude)   * 2 + 0.005
            let lonDelta = abs(riderCoordinate.longitude - driverCoordinate.longitude) * 2 + 0.005
            
            self.mapView.setRegion(MKCoordinateRegion(center: riderCoordinate, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)), animated: true)
        } else {
            self.mapView.setRegion(MKCoordinateRegion(center: riderCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)), animated: true)
        }
        
        mapView.removeAnnotations(mapView.annotations)
        
        let riderAnnotation = MKPointAnnotation()
        riderAnnotation.coordinate = riderCoordinate
        riderAnnotation.title = "Your location"
        
        if self.previousLocation == nil {
            self.previousLocation = riderCoordinate
        }
        
        mapView.addAnnotation(riderAnnotation)
        
        if let driverCoordinate = driverCoordinate {
            let driverAnnotation = MKPointAnnotation()
            driverAnnotation.coordinate = driverCoordinate
            driverAnnotation.title = "Driver location"
            
            self.mapView.addAnnotation(driverAnnotation)
        }
    }
}

//--------------------------------------
// MARK: - MKMapViewDelegate -
//--------------------------------------

extension RiderViewController: MKMapViewDelegate {
    
}
