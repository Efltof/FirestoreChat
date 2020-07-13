//
//  NewMessageController.swift
//  GameOfChats
//
//  Created by Александр Кондрашин on 09/07/2019.
//  Copyright © 2019 Alexander Kondrashin. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class NewMessageController: UITableViewController {
    
    var cellId = "cellId"
    
    var users = [User]()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(handleCancel))
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        fetchUser()
    }
    
    func fetchUser() {
        let db = Firestore.firestore()
        db.collection("users").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                for document in querySnapshot!.documents {
                    let user = User()
                    
                    user.userName = document.data()["userName"] as? String
                    user.email = document.data()["email"] as? String
                    user.profileImageUrl = document.data()["profileImageUrl"] as? String
                    user.id = document.documentID
                    
                    self.users.append(user)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                        self.tableView.reloadData()
                    }
                    
                }
            }
        }
    }
   
    
    @objc func handleCancel() {
        dismiss(animated: true, completion: nil)
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UserCell(style: .subtitle, reuseIdentifier: cellId)
        
        let user = users[indexPath.row]
        
        cell.textLabel?.text = user.userName
        cell.detailTextLabel?.text = user.email
        
        if let profileImageUrl = user.profileImageUrl {
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        return cell
    }
    var messagesController : MessageController?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true) {
            let user = self.users[indexPath.row]
            self.messagesController?.showChatControllerForUser(user: user)
        }
    }
}



