//
//  DiscussionsViewController.swift
//  LeasingManagers
//
//  Created by Ayushman Dey on 03/06/17.
//  Copyright © 2017 Ayushman Dey. All rights reserved.
//

import UIKit
import Firebase

class DiscussionsViewController: UIViewController ,UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var discussionTextField: UITextField!
    
    //MARK: Properties
    var addressName: String?
    var senderName:String?
    var addressRef: FIRDatabaseReference?
    
    private lazy var discussionRef: FIRDatabaseReference = self.addressRef!.child("discussions")

    private var discussions: [Discussion] = []
    private var discussionRefHandle: FIRDatabaseHandle?
    var address: Address? {
        didSet {
            self.navigationItem.title = address?.name
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.addressName
        //self.navigationItem.title = "Logout"
        
        self.tableView.reloadData()
        observeDiscussions()

    }
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discussions.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell?
        
        cell = tableView.dequeueReusableCell(withIdentifier: "discussionCell", for: indexPath)
        cell?.textLabel?.text = discussions[indexPath.row].name
        return cell!
    }
    // MARK: Firebase related methods
    private func observeDiscussions() {
        discussionRef = addressRef!.child("discussions")
        // Use the observe method to listen for new channels being written to the Firebase DB
        discussionRefHandle = discussionRef.observe(.childAdded, with: { (snapshot) -> Void in
            let channelData = snapshot.value as! Dictionary <String, AnyObject>
            let id = snapshot.key
            if let name = channelData["discussion"] as! String!, name.characters.count > 0 {
                self.discussions.append(Discussion(name: name, id: id))
                self.tableView.reloadData()
            } else {
                print("Error! Could not decode channel data")
            }
        })
    }
    deinit {
        if let refHandle = discussionRefHandle {
            discussionRef.removeObserver(withHandle: refHandle)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
            let discussion = discussions[indexPath.row]
            self.performSegue(withIdentifier: "chatSegue", sender: discussion)
        
    }
    @IBAction func createDiscussion(_ sender: UIButton) {
        if let name = discussionTextField?.text{
            let newDiscussionRef = discussionRef.childByAutoId()
            let discussionItem = ["discussion" : name]
            newDiscussionRef.setValue(discussionItem)
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let discussion = sender as? Discussion {
            let chatVC = segue.destination as! ChatViewController
            
            chatVC.senderDisplayName = senderName
            chatVC.discussion = discussion
            chatVC.discussionRef = discussionRef.child(discussion.id)
        }
    }

}
