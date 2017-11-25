//
//  LoginHandler.swift
//  WhoDat
//
//  Created by Sathyavarathan Sivabalasingam on 10/14/17.
//  Copyright © 2017 LTAC. All rights reserved.
//

import Foundation
import UIKit
import Firebase

extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc func handleProfilePicture() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImage: UIImage?
        
        if let editedImage = info[UIImagePickerControllerEditedImage] {
            selectedImage = editedImage as? UIImage
        } else if let originalImage = info[UIImagePickerControllerOriginalImage] {
           selectedImage = originalImage as? UIImage
        }
        
        if selectedImage != nil {
            profilePictureView.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
        
    }
    
    func handleRegister(verificationCode: String) {
        guard let phone = phoneField.text, let name = nameField.text
            else {
                print("Invalid form inputs!")
                return
        }
        
        let verificationID = UserDefaults.standard.string(forKey: "authVerificationID")
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID!,
            verificationCode: verificationCode)
        
        Auth.auth().signIn(with: credential) { (user, error) in
            if error != nil {
                print(error ?? "Error when registering new user!")
                return
            }
            guard let uid = user?.uid else {return}
            
            let imageName = NSUUID().uuidString
            let storageRef = Storage.storage().reference().child("profile_pictures").child("\(imageName).jpg")
            
            if let profileImage = self.profilePictureView.image, let uploadData = UIImageJPEGRepresentation(profileImage, 0.1) {
                storageRef.putData(uploadData, metadata: nil, completion: {(metadata, error) in
                    if error != nil {
                        print(error ?? "Error while uploading profile picture!")
                        return
                    }
                    
                    if let imageUrl = metadata?.downloadURL()?.absoluteString {
                        let values = ["name" : name, "phone" : phone, "profileImageUrl": imageUrl, "token": Messaging.messaging().fcmToken!]
                        self.registerAccount(uid: uid, values: values)
                    }
                    
                })
            }
        }
    }
    
    private func registerAccount(uid: String, values: [String: Any]) {
        let ref = Database.database().reference()
        let usersRef = ref.child("users").child(uid)
        
        usersRef.updateChildValues(values, withCompletionBlock:
            {(err, ref) in
                if err != nil {
                    print(err ?? "Error when adding new user!")
                    return
                }
                
                LocalUserRepository.shared().reset()
                self.messageController?.fetchUserAndSetNavBar()

                self.dismiss(animated: true, completion: nil)
        })

    }
    
}
