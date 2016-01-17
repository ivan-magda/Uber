//
//  DriverLocation.swift
//  ParseStarterProject-Swift
//
//  Created by Иван Магда on 17.01.16.
//  Copyright © 2016 Parse. All rights reserved.
//

import Foundation
import Parse

public typealias DriverLocationResultBlock = (location: PFGeoPoint?, error: NSError?) -> Void

class DriverLocation: PFObject, PFSubclassing {
    //--------------------------------------
    // MARK: - Types
    //--------------------------------------
    
    enum Keys: String {
        case username
        case location
        case createdAt
    }
    
    //--------------------------------------
    // MARK: - Properties
    //--------------------------------------
    
    /// Username of the drider.
    @NSManaged var username: String
    
    /// Current location of the drider.
    @NSManaged var location: PFGeoPoint
    
    //--------------------------------------
    // MARK: - PFSubclassing
    //--------------------------------------
    
    override class func initialize() {
        struct Static {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }
    
    /// Class name of the DriverLocation object.
    class func parseClassName() -> String {
        return "DriverLocation"
    }
    
    //--------------------------------------
    // MARK: - Quering
    //--------------------------------------
    
    class func createDriverLocationIfNeeded(driverUsername username: String, coordinate: CLLocationCoordinate2D, block: RequestResultBlock) {
        let query = PFQuery(className: DriverLocation.parseClassName())
        query.whereKey(DriverLocation.Keys.username.rawValue, equalTo: username)
        
        query.countObjectsInBackgroundWithBlock() { (count, error) in
            if let error = error {
                block(success: false, error: error)
            } else if count == 0 {
                let driverLcoation = DriverLocation()
                driverLcoation.username = username
                driverLcoation.location = PFGeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
                
                driverLcoation.saveInBackgroundWithBlock() { (success, error) in
                    if success {
                        block(success: success, error: nil)
                    } else {
                        block(success: false, error: error)
                    }
                }
            } else {
                block(success: true, error: nil)
            }
        }
    }
    
    class func updateLocationFromCoordinate(coordinate: CLLocationCoordinate2D, driverUsername username: String, block: RequestResultBlock) {
        let query = PFQuery(className: DriverLocation.parseClassName())
        query.whereKey(DriverLocation.Keys.username.rawValue, equalTo: username)
        
        query.findObjectsInBackgroundWithBlock() { (locations, error) in
            if let error = error {
                block(success: false, error: error)
            } else if let locations = locations as? [DriverLocation] where locations.count > 0 {
                for driverLocation in locations {
                    driverLocation.location = PFGeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    
                    driverLocation.saveInBackgroundWithBlock() { (success, error) in
                        if success {
                            block(success: success, error: nil)
                        } else {
                            block(success: false, error: error)
                        }
                    }
                }
            } else {
                block(success: false, error: nil)
            }
        }
    }
    
    class func getDriverLocationFromUsername(username: String, block: DriverLocationResultBlock) {
        let query = PFQuery(className: DriverLocation.parseClassName())
        query.whereKey(DriverLocation.Keys.username.rawValue, equalTo: username)
        
        query.findObjectsInBackgroundWithBlock() { (driver, error) in
            if let error = error {
                block(location: nil, error: error)
            } else if let driver = driver as? [DriverLocation] where driver.count > 0 {
                assert(driver.count == 1)
                
                block(location: driver[0].location, error: nil)
            } else {
                block(location: nil, error: nil)
            }
        }
    }
}