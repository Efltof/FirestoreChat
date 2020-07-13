//
//  LoginController+handlers.swift
//  GameOfChats
//
//  Created by Александр Кондрашин on 10/07/2019.
//  Copyright © 2019 Alexander Kondrashin. All rights reserved.
//


import UIKit
import FirebaseFirestore
import FirebaseAuth
import Firebase
import CoreServices
import AVFoundation



extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    

  @objc func handleSelectProfileImageView() {
    let picker = UIImagePickerController()
    picker.delegate = self
    picker.allowsEditing = true
    
    present(picker, animated: true, completion: nil)
    
    }
    
    @objc func handleRegister() {
        
        guard let email = emailTextField.text, let password = passwordTextField.text, let name = nameTextField.text  else  {
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            if error != nil {
                print("error, \(error!)")
                return
            } else {
                
                //Sucess authentication user
                guard let uid = Auth.auth().currentUser?.uid else { return }
                let imageName = NSUUID().uuidString
                
                let storage = Storage.storage().reference().child("profile_images").child("\(imageName).jpg")
                let image = self.profileImageView.image
                if let uploadData = image?.jpegData(compressionQuality: 0.1) {
                    storage.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                        if error != nil {
                            print(error)
                            return
                        } else {
                            storage.downloadURL(completion: { (url, error) in
                                
                                if let profileImageUrl = url?.absoluteString {
                                    let data = ["userName" : name, "email" : email,"profileImageUrl" : profileImageUrl]
                                    self.registerUserIntoDatabaseWithUID(uid: uid, dataToAdd: data)
                                    
                                }
                            })
                        }
                    })
                }
            }
        }
    }
    
    private func registerUserIntoDatabaseWithUID(uid: String, dataToAdd: [String : Any]) {
        let ref = Firestore.firestore().collection("users").document("\(uid)")
        ref.setData(dataToAdd, completion: { (error) in
            if error != nil {
                print(error!)
            } else {
                
                let user = User()
                user.userName = dataToAdd["userName"] as? String
                user.profileImageUrl = dataToAdd["profileImageUrl"] as? String
                user.email = dataToAdd["email"] as? String
                
                self.messagesController?.setupNavBarWithUser(user: user)
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var selectedImageFromPicker = UIImage()
        
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImageFromPicker = editedImage
        }
        
        
        if let originaImage = info[.originalImage] as? UIImage  {
            selectedImageFromPicker = originaImage
        }
        
        if let selectedImage = selectedImageFromPicker as? UIImage {
            profileImageView.image = selectedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
}
