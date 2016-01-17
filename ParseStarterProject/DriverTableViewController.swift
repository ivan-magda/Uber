//
//  DriverTableViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Иван Магда on 16.01.16.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit

class DriverTableViewController: UITableViewController {
    //--------------------------------------
    // MARK: - Types
    //--------------------------------------
    
    private enum SegueIdentifier: String {
        case showViewRequests
    }
    
    //--------------------------------------
    // MARK: - Properties
    //--------------------------------------
    
    private let cellReuseIdentifier = "cell"
    
    private var objects = [RiderRequest]()
    
    private var locationManager: CLLocationManager!
    private var previousLocationCoordinate: CLLocationCoordinate2D?
    
    //--------------------------------------
    // MARK: - View Life Cycle
    //--------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadObjects()
        setup()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        DriverLocation.createDriverLocationIfNeeded(driverUsername: PFUser.currentUser()!.username!, coordinate: self.previousLocationCoordinate ?? CLLocationCoordinate2DMake(0, 0)) { (success, error) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    //--------------------------------------
    // MARK: - Navigation
    //--------------------------------------
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == SegueIdentifier.showViewRequests.rawValue {
            let requestVC = segue.destinationViewController as! RequestViewController
            
            let selectedRow = tableView.indexPathForSelectedRow!.row
            let location = self.objects[selectedRow].location
            let locationCoordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
            requestVC.requestLocation = locationCoordinate
            
            requestVC.requestUsername = self.objects[selectedRow].username
        }
    }
    
    //--------------------------------------
    // MARK: - Private
    //--------------------------------------
    
    private func setup() {
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: Selector("loadObjects"), forControlEvents: UIControlEvents.ValueChanged)
        
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    //--------------------------------------
    // MARK: - Quering
    //--------------------------------------
    
    func loadObjects() {
        let query = PFQuery(className: RiderRequest.parseClassName())
        query.limit = 10
        
        if let locationCoordinate = self.previousLocationCoordinate {
            query.whereKey(RiderRequest.Keys.location.rawValue, nearGeoPoint: PFGeoPoint(latitude: locationCoordinate.latitude, longitude: locationCoordinate.longitude))
        }
        
        query.findObjectsInBackgroundWithBlock() { (requests, error) in
            self.refreshControl?.endRefreshing()
            
            if let error = error {
                print(error.localizedDescription)
            } else if let requests = requests as? [RiderRequest] {
                self.objects.removeAll(keepCapacity: true)
                
                for request in requests {
                    if request.driverResponded.characters.count <= 0 {
                        self.objects.append(request)
                    }
                }
                
                self.tableView.reloadData()
            }
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
    
    //--------------------------------------
    // MARK: - UITableViewDataSource
    //--------------------------------------
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.objects.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellReuseIdentifier)!
        
        let request = objects[indexPath.row]
        
        var distance = ""
        if let driverLocationCoordinate = self.previousLocationCoordinate {
            let riderLocation = CLLocation(latitude: request.location.latitude, longitude: request.location.longitude)
            let driverLocation = CLLocation(latitude: driverLocationCoordinate.latitude, longitude: driverLocationCoordinate.longitude)
            let distanceLocation = driverLocation.distanceFromLocation(riderLocation)
            
            let distanceInKilometers = distanceLocation / 1000.0
            let roundedDistance = round(distanceInKilometers * 10.0) / 10.0
            
            distance = "\(roundedDistance) km away"
        }
        
        cell.textLabel?.text = request.username
        cell.detailTextLabel?.text = distance
        
        return cell
    }
    
    //--------------------------------------
    // MARK: - UITableViewDelegate
    //--------------------------------------
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

//--------------------------------------
// MARK: - CLLocationManagerDelegate -
//--------------------------------------

extension DriverTableViewController: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordinate = manager.location?.coordinate {
            
            DriverLocation.updateLocationFromCoordinate(coordinate, driverUsername: PFUser.currentUser()!.username!, block: { (success, error) -> Void in
                if success {
                    print("Driver location updated")
                } else if let error = error {
                    print("Driver location update is failed with error: \(error.localizedDescription)")
                }
            })
            
            if self.previousLocationCoordinate == nil {
                self.previousLocationCoordinate = coordinate
                loadObjects()
            } else if self.previousLocationCoordinate!.latitude  != coordinate.latitude &&
                self.previousLocationCoordinate!.longitude != coordinate.longitude {
                    loadObjects()
            }
            
            self.previousLocationCoordinate = coordinate
        }
    }
}
