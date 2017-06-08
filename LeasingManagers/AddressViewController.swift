//
//  AddressViewController.swift
//  LeasingManagers
//
//  Created by Ayushman Dey on 05/06/17.
//  Copyright © 2017 Ayushman Dey. All rights reserved.
//

import UIKit
import SearchTextField
import Firebase
import FirebaseAuthUI
import FirebaseGoogleAuthUI

class AddressViewController: UIViewController {
    //Auth properties
    fileprivate var _authHandle: FIRAuthStateDidChangeListenerHandle!
    var user: FIRUser?
    var displayName = "Anonymous"
    
    //Address properties
    @IBOutlet weak var textField: SearchTextField!
    let list = ["449 Palo Verde Road, Gainesville, FL", "6731 Thompson Street, Gainesville, FL", "8771 Thomas Boulevard, Orlando, FL","1234 Verano Place, Orlando, FL"]
    
    var addressName: String?
    var addresses: [Address] = []
    private lazy var addressRef: FIRDatabaseReference = FIRDatabase.database().reference().child("addresses")
    private var addressRefHandle: FIRDatabaseHandle?

    override func viewDidLoad() {
        super.viewDidLoad()
        textField.filterStrings(list)
        textField.inlineMode = true
        textField.theme.placeholderColor = UIColor.gray
        
        
        //Check for user authentication state
        configureAuth()
        
        //Check for new addresses being added
        observeAddresses()
    }
    func configureAuth(){
        let provider: [FUIAuthProvider] = [FUIGoogleAuth()]
        FUIAuth.defaultAuthUI()?.providers = provider
        FUIAuth.defaultAuthUI()?.isSignInWithEmailHidden = true
        //Listen for changes in authorization state
        _authHandle = FIRAuth.auth()?.addStateDidChangeListener{
            (auth: FIRAuth, user: FIRUser?) in
            
            //Check if there's a current user
            if let activeUser = user{
                //Check if current app user is current FIRUser
                if self.user != activeUser{
                    self.user = activeUser
                    self.performSegue(withIdentifier: "showAddressDiscussions", sender: nil)
                }
            }else{
                //User must sign in
                self.loginSession()
            }
        }
    }
    func loginSession(){
        let authVC = FUIAuth.defaultAuthUI()!.authViewController()
        present(authVC, animated: true, completion: nil)
    }
    deinit{
        FIRAuth.auth()?.removeStateDidChangeListener(_authHandle)
        if let refHandle = addressRefHandle {
            addressRef.removeObserver(withHandle: refHandle)
        }
    }
    @IBAction func signUp(_ sender: UIButton) {
        if let addressName = textField?.text{
            let newAddressRef = addressRef.childByAutoId()
            let addressItem = ["address" : addressName]
            
            
            var obj : Address?
            var existing: Bool = false
            for i in addresses{
                if i.name == addressName{
                    obj = i
                    existing = true
                }
            }
            if existing == false{
                obj = Address(name: addressName, id: newAddressRef.key)
                newAddressRef.setValue(addressItem)
            }
            self.performSegue(withIdentifier: "showAddressDiscussions", sender: obj!)
        }
    }
    private func observeAddresses() {
        // Use the observe method to listen for new addresses being written to the Firebase DB
        addressRefHandle = addressRef.observe(.childAdded, with: { (snapshot) -> Void in
            let addressData = snapshot.value as! Dictionary <String, AnyObject>
            let id = snapshot.key
            if let name = addressData["address"] as! String!, name.characters.count > 0 {
                    self.addresses.append(Address(name: name, id: id))
            } else {
                print("Error! Could not decode address data")
            }
        })
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let address = sender as? Address {
            let navVc = segue.destination as! UINavigationController
            let discussionVC = navVc.viewControllers.first as! DiscussionsViewController
            
            discussionVC.addressName = textField.text
            discussionVC.addressRef = addressRef.child(address.id)
            discussionVC.address = address
        }
    }


}
/*
 if anonNameField?.text != "" {
 FIRAuth.auth()?.signInAnonymously(completion: { (user, error) in
 if let err = error{
 print(err.localizedDescription)
 return
 }
 self.performSegue(withIdentifier: "discussionSegue", sender: nil)
 })
 
 }
 */
