//
//  LoginViewController.swift
//  LeasingManagers
//
//  Created by Ayushman Dey on 02/06/17.
//  Copyright © 2017 Ayushman Dey. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    @IBOutlet weak var anonNameField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

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

