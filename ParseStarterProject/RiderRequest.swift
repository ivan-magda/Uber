//
//  RiderRequest.swift
//  ParseStarterProject-Swift
//
//  Created by Иван Магда on 16.01.16.
//  Copyright © 2016 Parse. All rights reserved.
//

import Foundation
import Parse

/// Class name of the RiderRequest object.
let RiderRequestClassName = "RiderRequest"

public typealias RiderRequestResultBlock = (success: Bool, error: NSError?) -> Void

class RiderRequest: PFObject, PFSubclassing {
    //--------------------------------------
    // MARK: - Types
    //--------------------------------------
    
    enum Keys: String {
        case username
        case location
    }
    
    //--------------------------------------
    // MARK: - Properties
    //--------------------------------------
    
    /// Username of the rider.
    @NSManaged var username: String
    
    /// Location of the rider.
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
    
    /// The class name of the object.
    class func parseClassName() -> String {
        return RiderRequestClassName
    }
    
    //--------------------------------------
    // MARK: - Requests
    //--------------------------------------
    
    class func cancelAnUberForUser(user: PFUser, block: RiderRequestResultBlock) {
        let query = PFQuery(className: RiderRequestClassName)
        query.whereKey(RiderRequest.Keys.username.rawValue, equalTo: user.username!)
        
        query.findObjectsInBackgroundWithBlock() { (objects, error) in
            if let error = error {
                block(success: false, error: error)
            } else if let request = objects as? [RiderRequest] {
                assert(request.count == 1)
                
                request[0].deleteInBackgroundWithBlock() { (success, error) in
                    if success {
                        block(success: true, error: nil)
                    } else {
                        block(success: false, error: error)
                    }
                }
            }
        }
    }
    
    class func requestAnUberForUser(user: PFUser, withLocationCoordinate coordinate: CLLocationCoordinate2D, block: RiderRequestResultBlock) {
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
}
