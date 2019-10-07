//
//  ChatLogController.swift
//  GameOfChats
//
//  Created by Александр Кондрашин on 16/07/2019.
//  Copyright © 2019 Alexander Kondrashin. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import Firebase
import CoreServices
import AVFoundation


class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate, UIImagePickerControllerDelegate , UINavigationControllerDelegate {
    
    var user : User? {
        didSet {
            navigationItem.title = user?.userName
            observeMessages()
        }
    }
    
    var messages = [Message]()
    
    var videoUrl : URL?
    
    //MARK: ObserveMessages
    func observeMessages() {
        guard let uid = Auth.auth().currentUser?.uid, let toId = user?.id else { return }
        
        let ref = Firestore.firestore().collection("user-messages").document(uid).collection("users").document(toId).collection("messages")
        
        ref.addSnapshotListener { (snapshot, error) in
            snapshot?.documentChanges.forEach({ (diff) in
                
                let messageId = diff.document.documentID
                let messageRef = Firestore.firestore().collection("messages").document(messageId)
                messageRef.getDocument(completion: { (document, error) in
                    guard let dictionary = document?.data() as? [String : Any] else { return }
                    
                    let message = Message(dictionary: dictionary)
                    
                    print("we fetched this message \(message.text)")
                    if message.chatPartnerId() == self.user?.id {
                        self.messages.append(message)

                        DispatchQueue.main.async {
                            self.collectionView.reloadData()
                            let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                            self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
                        }
                    }
                })
            })
        }
    }
    
  public lazy var inputTextField : UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholder = "Enter your message..."
        field.delegate = self
        return field
    }()
    
   let cellId = "cellId"
    //MARK: viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
    
        navigationItem.title = user?.userName
        collectionView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 58, right: 0)
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .white
        collectionView.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        setInputComponents()
        setupKeyboardObservers()
        
    }
    
    //MARK: CollectionView
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        
        cell.chatLogController = self
        
        let message = messages[indexPath.row]
        let text = message.text
        cell.textView.text = text
        
        setupCell(cell: cell, message: message)
        
        //modify bubbleView's width
        if let text = message.text {
            cell.bubbleWithAncher?.constant = estimateFrameForText(text: text).width + 30
            cell.textView.isHidden = false
        } else if message.imageUrl != nil {
            cell.textView.isHidden = true
            cell.bubbleWithAncher?.constant = view.frame.width / 2 // or 200
        }
    
        cell.playButton.isHidden = message.videoUrl == nil
        return cell
    }
    //MARK: Setup Cell
    private func setupCell(cell: ChatMessageCell, message : Message) {
        if let profileImageUrl = self.user?.profileImageUrl {
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        if let messageImageUrl = message.imageUrl {
            cell.messageImageView.loadImageUsingCacheWithUrlString(urlString: messageImageUrl)
            cell.messageImageView.isHidden = false
        } else {
            cell.messageImageView.isHidden = true
        }
        
        if message.fromId == Auth.auth().currentUser?.uid {
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = .white
            cell.profileImageView.isHidden = true
            
            cell.bubbleViewLeftAnchor?.isActive = false
            cell.bubbleViewRightAnchor?.isActive = true
            
            
        } else {
            cell.bubbleView.backgroundColor = UIColor(r: 240, g: 240, b: 240)
            cell.textView.textColor = .black
            cell.profileImageView.isHidden = false
            
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
            
        }
        
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        dismissKeyboard()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height : CGFloat = 80
        
        let message = messages[indexPath.item]
        if let text = message.text {
            height = estimateFrameForText(text: text).height + 20
        } else if let imageWidth = message.imageWidth?.floatValue , let imageHeight = message.imageHeight?.floatValue {
            //w1 / h1 = w2 / h2
            // for h1
            height = CGFloat(imageHeight / imageWidth * 200)
        }
        return CGSize(width: view.frame.width, height: height)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func estimateFrameForText(text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes:  [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func handleKeyboardDidShow() {
        let indexPath = IndexPath(item: messages.count - 1, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleKeyboardWillShow(notification: NSNotification) {
        let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        let keyboardDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        
        containerViewBottomAnchor?.constant = -keyboardFrame!.height
        UIView.animate(withDuration: keyboardDuration!) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func handleKeyboardWillHide(notification: NSNotification) {
        let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        let keyboardDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        
        containerViewBottomAnchor?.constant = 0
        UIView.animate(withDuration: keyboardDuration!) {
            self.view.layoutIfNeeded()
        }
    }
    
    
    
    var containerViewBottomAnchor: NSLayoutConstraint?
    
    func setInputComponents() {
        let containerView = UIView()
        containerView.backgroundColor = .white
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        //x,y,width, height
        containerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        
        containerViewBottomAnchor = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        containerViewBottomAnchor?.isActive = true
        
        containerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        containerView.heightAnchor.constraint(equalToConstant:  50).isActive = true
        
        let uploadImageView = UIButton(type: .custom)
        uploadImageView.setImage(UIImage(named: "upload_icon_image"), for: .normal)
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        uploadImageView.addTarget(self, action: #selector(handleUploadTap), for: .allTouchEvents)
        containerView.addSubview(uploadImageView)
        
        //x,y,width, height
        uploadImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        

        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSender), for: .touchUpInside)
        containerView.addSubview(sendButton)
        //x,y,width, height
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        containerView.addSubview(inputTextField)
        
        //x,y,width, height
        inputTextField.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor,constant: 8).isActive = true
        inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
        inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(separatorView)
        
        separatorView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
    }
    
    @objc func handleUploadTap() {
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        imagePickerController.mediaTypes = [kUTTypeImage as String , kUTTypeMovie as String]
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let url = info[.mediaURL] as? NSURL {
            
            guard let absoluteUrl = url.absoluteURL else { return }
            
            handleVideoSelectedForUrl(videoUrl: absoluteUrl)
        }
            handleImageSelectedForInfoDictionary(info: info)
        
            dismiss(animated: true, completion: nil)
        }
    
   private func handleVideoSelectedForUrl(videoUrl : URL) {
            //попробовать изменить вариант загрузки на putFile(fromUrl)
            print("url for this file is: ", videoUrl)
        let filename = NSUUID().uuidString + ".mov"
            
    let ref = Storage.storage().reference().child("message_movies").child(filename)
            ref.putFile(from: videoUrl, metadata: nil) { (metadata, error) in
                if error != nil {
                    print(error)
                    return
                }
                self.videoUrl = videoUrl
                if let thumbnailImage = self.thumbnailImageForFileUrl(fileUrl: videoUrl) {
                    self.uploadFirebaseStorageUsingImage(image: thumbnailImage, clousure: self.setAndSendProperties(imageUrl: image:))
            }
        }
    }
    
    func setAndSendProperties(imageUrl: String, image: UIImage) {
        guard let urlForVideo = videoUrl else { return }
        let properties : [String : Any] = ["imageUrl": imageUrl, "imageWidth" : image.size.width, "imageHeight" : image.size.height, "videoUrl" : urlForVideo.absoluteString]
        self.sendMessageWithProperties(properties: properties)
    }
    
    private func thumbnailImageForFileUrl(fileUrl: URL) -> UIImage? {
        let asset = AVAsset(url: fileUrl)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        do {
        let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1,timescale: 60), actualTime: nil)
            return UIImage(cgImage: thumbnailCGImage)
        } catch let error {
            print(error)
        }
        return nil
    }
    
    
    
  private  func handleImageSelectedForInfoDictionary(info : [UIImagePickerController.InfoKey : Any]) {
        var selectedImageFromPicker = UIImage()

        
            if let editedImage = info[.editedImage] as? UIImage {
                selectedImageFromPicker = editedImage
            }
            
            
            if let originaImage = info[.originalImage] as? UIImage  {
                selectedImageFromPicker = originaImage
            }
            
            if let selectedImage = selectedImageFromPicker as? UIImage {
                uploadFirebaseStorageUsingImage(image: selectedImage, clousure: getImageUrlAndTakeItToTheSameNameFunction(imageUrl:image:))
                
            }
    }
    func getImageUrlAndTakeItToTheSameNameFunction(imageUrl : String, image: UIImage) {
        self.sendMessageWithImageUrl(imageUrl, image: image)
        
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func uploadFirebaseStorageUsingImage(image : UIImage, clousure: @escaping (_ imageUrl : String, _ image: UIImage) -> Void) {
         let imageName = NSUUID().uuidString
            
        let ref = Storage.storage().reference().child("message_images").child("\(imageName).jpg")
        
       
        if let uploadData = image.jpegData(compressionQuality: 0.2) {
            ref.putData(uploadData, metadata: nil) { (metadata, error) in
                
                if error != nil {
                    print(error)
                    return
                }
                ref.downloadURL { (url, error) in
                    guard let imageUrl = url?.absoluteString else {return}
                    clousure(imageUrl, image)
                }
            }
        }
    }
    
    //MARK: Send Image With Url
    func sendMessageWithImageUrl(_ imageUrl : String, image : UIImage) {
        var properties : [String : Any] = ["imageUrl" : imageUrl, "imageWidth" : image.size.width, "imageHeight" : image.size.height]
        sendMessageWithProperties(properties: properties)
    }
    
    @objc func handleSender() {
        var properties : [String : Any] = ["text" : inputTextField.text!]
        sendMessageWithProperties(properties: properties)
    }
    
    private func sendMessageWithProperties(properties: [String : Any]) {
        
        let ref = Firestore.firestore().collection("messages").document()
        let toId = user?.id
        let timestamp = Int(NSDate().timeIntervalSince1970)
        let fromId = Auth.auth().currentUser?.uid
        
        var values : [String : Any] = ["toId" : toId, "fromId" : fromId, "timestamp" : timestamp]
        
        properties.forEach {( values[$0] = $1 )}
        
        
        ref.setData(values) { (error) in
            if error != nil {
                print(error)
            } else {
                print("success")
                
                let messageId = ref.documentID
                //step 1
                let userRef = Firestore.firestore().collection("user-messages").document(fromId!).collection("users").document(toId!)
                userRef.setData([toId! : 1])
                //step 2
                let userMessageRef =  Firestore.firestore().collection("user-messages").document(fromId!).collection("users").document(toId!).collection("messages").document(messageId)
                
                userMessageRef.setData([messageId : 1])
                
                //step 1
                let recipienUserRef = Firestore.firestore().collection("user-messages").document(toId!).collection("users").document(fromId!)
                recipienUserRef.setData([fromId! : 1])
                
                let recipienUserMessageRef = Firestore.firestore().collection("user-messages").document(toId!).collection("users").document(fromId!).collection("messages").document(messageId)
                
                recipienUserMessageRef.setData([messageId : 1])
                
                self.inputTextField.text = ""
            }
        }
    }
    
    func textFieldShouldReturn(_ textField : UITextField) -> Bool {
        if textField.text?.isEmpty == true {
            return false
        } else {
            handleSender()
            return true
        }
    }
    
    var startingFrame : CGRect?
    var blackBackgroundView : UIView?
    var startingImageView : UIImageView?
    
    func performZoomInForStartingImageView(startingImageView: UIImageView) {
        self.startingImageView = startingImageView
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
        print(startingImageView)
        let zoomingImageView = UIImageView(frame: startingFrame!)
        zoomingImageView.image = startingImageView.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        
        if let keyWindow = UIApplication.shared.keyWindow {
            
            blackBackgroundView = UIView(frame: keyWindow.frame)
            blackBackgroundView?.backgroundColor = .black
            blackBackgroundView?.alpha = 0
            keyWindow.addSubview(blackBackgroundView!)
            
            keyWindow.addSubview(zoomingImageView)
            
            zoomingImageView.layer.cornerRadius = 16
            zoomingImageView.clipsToBounds = true
            
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                
                self.blackBackgroundView?.alpha = 1
                self.inputTextField.alpha = 0
                self.startingImageView?.isHidden = true
                
                let height = self.startingFrame!.height / self.startingFrame!.width * keyWindow.frame.width
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                
                zoomingImageView.center = keyWindow.center
                   }, completion: nil)
        }
    }
    @objc func handleZoomOut(tapGesture: UITapGestureRecognizer) {
        
        if let zoomOutImageView = tapGesture.view {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                zoomOutImageView.layer.cornerRadius = 16
                zoomOutImageView.clipsToBounds = true
                
                zoomOutImageView.frame = self.startingFrame!
                self.blackBackgroundView?.alpha = 0
                self.inputTextField.alpha = 1
                
            }) { (completed) in
                zoomOutImageView.removeFromSuperview()
                self.blackBackgroundView?.removeFromSuperview()
                self.startingImageView?.isHidden = false
                
            }
        }
    }
}
