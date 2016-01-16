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
}
