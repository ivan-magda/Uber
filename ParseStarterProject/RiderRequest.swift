//
//  RiderRequest.swift
//  ParseStarterProject-Swift
//
//  Created by Иван Магда on 16.01.16.
//  Copyright © 2016 Parse. All rights reserved.
//

import Foundation
import Parse

public typealias RequestResultBlock = (success: Bool, error: NSError?) -> Void

class RiderRequest: PFObject, PFSubclassing {
    //--------------------------------------
    // MARK: - Types
    //--------------------------------------
    
    enum Keys: String {
        case username
        case location
        case driverResponded
        case createdAt
    }
    
    //--------------------------------------
    // MARK: - Properties
    //--------------------------------------
    
    /// Username of the rider.
    @NSManaged var username: String
    
    /// Current location of the rider.
    @NSManaged var location: PFGeoPoint
    
    /// Username of the responded drider.
    @NSManaged var driverResponded: String
    
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
    
    /// Class name of the RiderRequest object.
    class func parseClassName() -> String {
        return "RiderRequest"
    }
    
    //--------------------------------------
    // MARK: - Requests
    //--------------------------------------
    
    class func cancelAnUberForUser(user: PFUser, block: RequestResultBlock) {
        let query = PFQuery(className: RiderRequest.parseClassName())
        query.whereKey(RiderRequest.Keys.username.rawValue, equalTo: user.username!)
        query.orderByDescending(RiderRequest.Keys.createdAt.rawValue)
        
        query.findObjectsInBackgroundWithBlock() { (objects, error) in
            if let error = error {
                block(success: false, error: error)
            } else if let request = objects as? [RiderRequest] {
                request[request.count - 1].deleteInBackgroundWithBlock() { (success, error) in
                    if success {
                        block(success: true, error: nil)
                    } else {
                        block(success: false, error: error)
                    }
                }
            }
        }
    }
    
    class func requestAnUberForUser(user: PFUser, withLocationCoordinate coordinate: CLLocationCoordinate2D, block: RequestResultBlock) {
        let riderRequest = RiderRequest()
        riderRequest.username = user.username!
        riderRequest.location = PFGeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        riderRequest.saveInBackgroundWithBlock() { (success, error) in
            if let error = error {
                block(success: false, error: error)
            } else {
                block(success: true, error: nil)
            }
        }
    }
    
    class func respondForRiderRequest(riderUsername rider: String, driverUsername driver: String, block: RequestResultBlock) {
        let query = PFQuery(className: RiderRequest.parseClassName())
        query.whereKey(RiderRequest.Keys.username.rawValue, equalTo: rider)
        
        query.findObjectsInBackgroundWithBlock() { (objects, error) in
            if let error = error {
                block(success: false, error: error)
            } else if let requests = objects as? [RiderRequest] {
                let request = requests[requests.count - 1]
                request.driverResponded = driver
                
                request.saveInBackgroundWithBlock() { (success, error) in
                    if success {
                        block(success: true, error: nil)
                    } else {
                        block(success: false, error: error)
                    }
                }
            }
        }
    }
}
