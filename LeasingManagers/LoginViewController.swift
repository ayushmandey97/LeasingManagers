//
//  LoginViewController.swift
//  LeasingManagers
//
//  Created by Ayushman Dey on 02/06/17.
//  Copyright © 2017 Ayushman Dey. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuthUI

class LoginViewController: UIViewController {
    
    //fileprivate var _authHandle: FIRAuthStateDidChangeListener!
    var user: FIRUser?
    var displayName = "Anonymous"
    @IBOutlet weak var anonNameField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        //configureAuth()
    }
    /*func configureAuth(){
        //Listen for changes in authorization state
        _authHandle = FIRAuth.addStateDidChangeListener{
            (auth: FIRAuth, user: FIRUser?) in
            
            //Check if there's a current user
            if let activeUser = user{
                //Check of current app user is current FIRUser
                if self.user != activeUser{
                    self.user = activeUser
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
    }*/

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func login(_sender: UIButton){
        if anonNameField?.text != "" {
            FIRAuth.auth()?.signInAnonymously(completion: { (user, error) in
                if let err = error{
                    print(err.localizedDescription)
                    return
                }
                self.performSegue(withIdentifier: "discussionSegue", sender: nil)
            })
        
        }
            
            
    }
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        let navigationVC = segue.destination as! UINavigationController
        let discussionVC = navigationVC.viewControllers.first as! DiscussionsViewController
        discussionVC.senderName = anonNameField.text
    }

}

