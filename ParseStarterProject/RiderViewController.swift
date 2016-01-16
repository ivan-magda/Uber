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
