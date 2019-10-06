//
//  ViewController.swift
//  GameOfChats
//
//  Created by Александр Кондрашин on 07/07/2019.
//  Copyright © 2019 Alexander Kondrashin. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class MessageController: UITableViewController {
    
    let cellId = "cellId"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        
        let image = UIImage(named: "newMessageIcon")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(handleNewMessage))
        
        checkIfUserIsLoggedIn()
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        
        
        //observeMessages()
        
     
        
        
    }
    
    var messages = [Message]()
    
    var messagesDictionary = [String : Message]()
    
    func observeUserMessages() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let ref = Firestore.firestore().collection("user-messages").document(uid).collection("messages")
        ref.addSnapshotListener { (DocumentSnapshot, error) in
            
            DocumentSnapshot?.documentChanges.forEach({ (diff) in
                print(diff.document.data())
                let messageID = diff.document.documentID
                let messageRef = Firestore.firestore().collection("messages").document(messageID)
                
                messageRef.getDocument(completion: { (document, error) in
                    guard let dataFromDocument = document?.data() else { return }
                    let message = Message(dictionary: dataFromDocument)
                    
                    // self.messages.append(message)
                    
                    if let chatPartnerId = message.chatPartnerId() {
                        self.messagesDictionary[chatPartnerId] = message
                        self.messages = Array(self.messagesDictionary.values)
                        
                        self.messages.sort(by: { (message1, message2) -> Bool in
                            return Int32(message1.timestamp!) > Int32(message2.timestamp!)
                            
                        })
                    }
                    DispatchQueue.main.async {
                        print("reload")
                        self.tableView.reloadData()
                    }
                })
            })
        }
    }
    var timer : Timer?
    //FIXME: Add timer 
    @objc func handleReloadTable() {
        DispatchQueue.main.async {
            print("reload")
            self.tableView.reloadData()
        }
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        
        let message = messages[indexPath.row]
        cell.message = message
        

        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       let message = messages[indexPath.row]
        print(message)
        
        guard let chatPartnerId = message.chatPartnerId() else { return }
        
        let ref = Firestore.firestore().collection("users").document(chatPartnerId)
        ref.getDocument { (DocumentSnapshot, error) in
            if error != nil {
                print(error)
            } else {
                print(DocumentSnapshot)
                guard let dictionary = DocumentSnapshot?.data() else { return }
                let user = User()
                
                user.id = chatPartnerId
                user.userName = dictionary["userName"] as? String
                user.email = dictionary["email"] as? String
                user.profileImageUrl = dictionary["profileImageUrl"] as? String
               
                
                self.showChatControllerForUser(user: user)
                
            }
        }
    }
    
    @objc func handleNewMessage() {
        let newMessageController = NewMessageController()
        newMessageController.messagesController = self
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
    }
    
    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            perform(#selector(handleLogout),with: nil, afterDelay: 0)
        } else {
            fetchUserAndSetupNavBarTitle()
        }
    }
    
    func fetchUserAndSetupNavBarTitle() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        print(uid)
        let docRef = Firestore.firestore().collection("users").document(uid)
        docRef.getDocument { (document, error) in
            if let dictionary = document?.data() {
                print("Document data: \(dictionary)")
                
                let user = User()
                user.userName = dictionary["userName"] as? String
                user.email = dictionary["email"] as? String
                user.profileImageUrl = dictionary["profileImageUrl"] as? String
                
                //FIXME: - Create a imageview in title on navbar (ep 7)
                
                self.setupNavBarWithUser(user: user)
//                self.navigationItem.title = user.userName
            } else {
                print("Document is not exist")
            }
        }
    }
    
    func setupNavBarWithUser(user: User) {
        
        
        messages.removeAll()
        messagesDictionary.removeAll()
        
        tableView.reloadData()
        
        observeUserMessages()
        
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
//        titleView.backgroundColor = UIColor.red
        titleView.isUserInteractionEnabled = true
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleView.addSubview(containerView)
        
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        if let profileImageUrl = user.profileImageUrl {
            profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        containerView.addSubview(profileImageView)
        
        //ios 9 constraint anchors
        //need x,y,width,height anchors
        profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        let nameLabel = UILabel()
        
        containerView.addSubview(nameLabel)
        nameLabel.text = user.userName
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        //need x,y,width,height anchors
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        
        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        
    
        self.navigationItem.titleView = titleView
//        self.navigationController?.navigationBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showChatController)))
        self.navigationController?.navigationBar.isUserInteractionEnabled = true
        
     }
    
    @objc func showChatControllerForUser(user: User) {
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
        
    }
    
    @objc func handleLogout() {
        
        do {
          try Auth.auth().signOut()
        } catch {
            print(error)
        }
        
        let loginController = LoginController()
        loginController.messagesController = self
        present(loginController, animated: true, completion: nil)
    }
    
}
