/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

import UIKit
import Parse

class AuthorizationViewController: UIViewController {
    //--------------------------------------
    // MARK: - Types
    //--------------------------------------
    
    private enum SegueIdentifier: String {
        case loginRider
        case loginDriver
    }
    
    private enum UserKeys: String {
        case isDriver
    }
    
    private enum UserRole: String {
        case Rider
        case Driver
        
        static func isDriver(driver: Bool) -> UserRole {
            if driver {
                return .Driver
            } else {
                return .Rider
            }
        }
    }
    
    //--------------------------------------
    // MARK: - Properties
    //--------------------------------------
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var riderLabel: UILabel!
    @IBOutlet weak var driverLabel: UILabel!
    @IBOutlet weak var modeSwitch: UISwitch!
    
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var toggleSignUpButton: UIButton!
    
    /// Is sign up or log in account.
    private var isSignUpState = true
    
    //--------------------------------------
    // MARK: - View Life Cycle
    //--------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.username.delegate = self
        self.password.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let user = PFUser.currentUser() {
            if let isDriver = user[UserKeys.isDriver.rawValue] as? Bool {
                doneOnAuthorizationWithUserRole(UserRole.isDriver(isDriver))
            }
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        
        self.view.endEditing(true)
    }
    
    //--------------------------------------
    // MARK: - Alert
    //--------------------------------------
    
    private func displayAlert(title title: String, message: String, handler: (() -> ())?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { action in
            if let handler = handler {
                handler()
            }
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //--------------------------------------
    // MARK: - Navigation
    //--------------------------------------
    
    private func doneOnAuthorizationWithUserRole(role: UserRole) {
        switch role {
        case .Driver:
            self.performSegueWithIdentifier(SegueIdentifier.loginDriver.rawValue, sender: self)
        case .Rider:
            self.performSegueWithIdentifier(SegueIdentifier.loginRider.rawValue, sender: self)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == SegueIdentifier.loginDriver.rawValue {
            print(SegueIdentifier.loginDriver.rawValue)
        } else if segue.identifier == SegueIdentifier.loginRider.rawValue {
            print(SegueIdentifier.loginRider.rawValue)
        }
    }
    
    //--------------------------------------
    // MARK: - Actions
    //--------------------------------------
    
    @IBAction func signUp(sender: AnyObject) {
        self.view.endEditing(true)
        
        if username.text == "" || password.text == "" {
            displayAlert(title: "Missing Field(s)", message: "Username and password are required", handler: nil)
        } else {
            if self.isSignUpState {
                let isDriver = self.modeSwitch.on
                
                let user = PFUser()
                user.username = self.username.text
                user.password = self.password.text
                user[UserKeys.isDriver.rawValue] = isDriver
                
                user.signUpInBackgroundWithBlock() { (succeeded, error) in
                    if let error = error {
                        self.displayAlert(title: "Sign Up Failed", message: error.localizedDescription, handler: nil)
                    } else {
                        self.doneOnAuthorizationWithUserRole(UserRole.isDriver(isDriver))
                    }
                }
            } else {
                PFUser.logInWithUsernameInBackground(self.username.text!, password: self.password.text!) { (user, error) in
                    if let error = error {
                        self.displayAlert(title: "Login Failed", message: error.localizedDescription, handler: nil)
                    } else if let user = user {
                        let isDriver = user[UserKeys.isDriver.rawValue] as! Bool
                        
                        self.doneOnAuthorizationWithUserRole(UserRole.isDriver(isDriver))
                    }
                }
            }
        }
    }
    
    @IBAction func toggleSignUp(sender: AnyObject) {
        self.view.endEditing(true)
        
        if self.isSignUpState {
            self.signUpButton.setTitle("Log In", forState: .Normal)
            self.toggleSignUpButton.setTitle("Sign Up", forState: .Normal)
            
            self.isSignUpState = false
            
            self.riderLabel.alpha = 0.0
            self.driverLabel.alpha = 0.0
            self.modeSwitch.alpha = 0.0
        } else {
            self.signUpButton.setTitle("Sign Up", forState: .Normal)
            self.toggleSignUpButton.setTitle("Log In", forState: .Normal)
            
            self.isSignUpState = true
            
            self.riderLabel.alpha = 1.0
            self.driverLabel.alpha = 1.0
            self.modeSwitch.alpha = 1.0
        }
    }
}

//--------------------------------------
// MARK: - UITextFieldDelegate -
//--------------------------------------

extension AuthorizationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
}
