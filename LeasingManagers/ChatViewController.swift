//
//  ChatViewController.swift
//  LeasingManagers
//
//  Created by Ayushman Dey on 04/06/17.
//  Copyright © 2017 Ayushman Dey. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import Firebase
import Photos

final class ChatViewController: JSQMessagesViewController {
    
    private lazy var messageRef: FIRDatabaseReference = self.discussionRef!.child("messages")
    private var newMessageRefHandle: FIRDatabaseHandle?
    
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    
    var messages = [JSQMessage]()
    var discussionRef: FIRDatabaseReference?
    var discussion: Discussion? {
        didSet {
            self.navigationItem.title = discussion?.name
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.senderId = FIRAuth.auth()?.currentUser?.uid
        
        // No avatars
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        observeMessages()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.purple)
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
 
    }
    
    //Asking datasource for message bubble image data corresponding to message item
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
       
        if message.senderId == senderId {
            return outgoingBubbleImageView
        } else {
            return incomingBubbleImageView
        }
    }
    //Remove avatars
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    //Creating a message
    private func addMessage(withId id: String, name: String, text: String) {
        if let message = JSQMessage(senderId: id, displayName: name, text: text) {
            messages.append(message)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView?.textColor = UIColor.white
        } else {
            cell.textView?.textColor = UIColor.black
        }
        return cell
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return 16
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        let senderDisplayName = message.senderDisplayName
        if senderDisplayName == FIRAuth.auth()?.currentUser?.displayName{
            return nil
        }
        
        return NSAttributedString(string: senderDisplayName!)
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        //Creating a child reference with a unique key
        let itemRef = messageRef.childByAutoId()
        
        let messageItem = [
            "senderId": senderId!,
            "senderName": senderDisplayName!,
            "text": text!,
            ]
        //Saving message to new child location
        itemRef.setValue(messageItem)
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        //Set input toolbar to empty after sending message
        finishSendingMessage()
        
        isTyping = false
    }
    private func observeMessages() {
        messageRef = discussionRef!.child("messages")
        
        //Query to limit synchronization to last 25 messages
        let messageQuery = messageRef.queryLimited(toLast:25)
        
        // Observe method to listen for new messages being written to the Firebase DB
        newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
            let messageData = snapshot.value as! Dictionary<String, String>
            
            if let id = messageData["senderId"] as String! , let name = messageData["senderName"] as String!, let text = messageData["text"] as String!, text.characters.count > 0 {
                
                //To add new text to the data source
                self.addMessage(withId: id, name: name, text: text)

                //To tell JSQMessageVC that the message has been received
                self.finishReceivingMessage()
            } else {
                print("Error! Could not decode message data")
            }
        })
    }
    
    //CONNECTIONS TO DISPLAY WHETHER A USER IS TYPING
    
    //This property holds an FIRDatabaseQuery to get all the users who are typing, which is ordered.
    private lazy var usersTypingQuery: FIRDatabaseQuery =
        self.discussionRef!.child("typingIndicator").queryOrderedByValue().queryEqual(toValue: true)
    
    
    // Firebase reference that tracks whether the local user is typing.
    private lazy var userIsTypingRef: FIRDatabaseReference =
        self.discussionRef!.child("typingIndicator").child(self.senderId)
    
    //To store whether local user is typing
    private var localTyping = false
    
    //Computed property to update localTyping and userIsTypingRef each time it’s changed.
    var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            localTyping = newValue
            userIsTypingRef.setValue(newValue)
        }
    }
    private func observeTyping() {
        let typingIndicatorRef = discussionRef!.child("typingIndicator")
        userIsTypingRef = typingIndicatorRef.child(senderId)
        userIsTypingRef.onDisconnectRemoveValue()
        
        usersTypingQuery.observe(.value) { (data: FIRDataSnapshot) in
            //If the current user is the only one who is typing
            if data.childrenCount == 1 && self.isTyping {
                return
            }
            
            //If others are typing, then show indicator
            self.showTypingIndicator = data.childrenCount > 0
            self.scrollToBottom(animated: true)
        }
    }
    
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        // If the text is not empty, the user is typing
        isTyping = textView.text != ""
    }
    
    

}
