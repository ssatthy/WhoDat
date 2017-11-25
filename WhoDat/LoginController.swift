//
//  LoginController.swift
//  WhoDat
//
//  Created by Sathyavarathan Sivabalasingam on 10/14/17.
//  Copyright © 2017 LTAC. All rights reserved.
//

import UIKit
import Firebase

class LoginController: UIViewController {

    var messageController: MessageController? = nil
    
    let inputsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(r: 80, g: 101, b: 161)
        button.setTitle("Login", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        
        return button
    }()
    
    let nameField: UITextField = {
        let name = UITextField()
        name.placeholder = "Name"
        name.translatesAutoresizingMaskIntoConstraints = false
        return name
    }()
    
    let nameSeparator: UIView = {
        let separator = UIView()
        separator.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        separator.translatesAutoresizingMaskIntoConstraints = false
        return separator
    }()
    
    let phoneField: UITextField = {
        let email = UITextField()
        email.placeholder = "Phone"
        email.translatesAutoresizingMaskIntoConstraints = false
        email.keyboardType = UIKeyboardType.phonePad
        return email
    }()

    lazy var profilePictureView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "profilepic")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 75
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleProfilePicture)))
        imageView.isUserInteractionEnabled = true
        
        return imageView
    }()
    
    @objc func handleLogin() {
        guard let phone = phoneField.text else {
                print("Invalid form inputs!")
                return
            }
        
        PhoneAuthProvider.provider().verifyPhoneNumber(phone, uiDelegate: nil, completion: {(verificationID, error) in
            if error != nil {
                print(error ?? "Something went wrong while signing up..")
            } else {
                UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            }
        })
        
        let registerAlert = UIAlertController(title: "Verify your phone number", message: "Enter the 6-digit code sent to \(phone)", preferredStyle: .alert)
        registerAlert.addTextField { (textField) in
            textField.placeholder = "6-digit code"
            textField.keyboardType = .numberPad
        }
        
        let verify = UIAlertAction(title: "Verify", style: .default, handler: {(UIAlertAction) in
            
            let textField = registerAlert.textFields![0]
            let code = textField.text
            self.handleRegister(verificationCode: code!)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        registerAlert.addAction(cancel)
        registerAlert.addAction(verify)
        present(registerAlert, animated: true, completion: nil)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(r: 61, g: 91, b: 151)
        self.hideKeyboardWhenTappedAround()
        view.addSubview(inputsContainerView)
        view.addSubview(loginButton)
        view.addSubview(profilePictureView)
        
        setupInputsContainerView()
        setupProfilePicture()

    }
    
    func setupProfilePicture() {
        profilePictureView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        profilePictureView.bottomAnchor.constraint(equalTo: inputsContainerView.topAnchor, constant: -12).isActive = true
        profilePictureView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        profilePictureView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        
    }
    
    func setupInputsContainerView() {

        inputsContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        inputsContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        inputsContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        inputsContainerView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        inputsContainerView.addSubview(nameField)
        nameField.topAnchor.constraint(equalTo: inputsContainerView.topAnchor).isActive = true
        nameField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        nameField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        nameField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/2).isActive = true
        
        inputsContainerView.addSubview(nameSeparator)
        
        nameSeparator.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor).isActive = true
        nameSeparator.topAnchor.constraint(equalTo: nameField.bottomAnchor).isActive = true
        nameSeparator.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        nameSeparator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        inputsContainerView.addSubview(phoneField)
        phoneField.topAnchor.constraint(equalTo: nameField.bottomAnchor).isActive = true
        phoneField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        phoneField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        phoneField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/2).isActive = true
        
        loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginButton.topAnchor.constraint(equalTo: inputsContainerView.bottomAnchor, constant: 12).isActive = true
        loginButton.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        loginButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}

extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat) {
        self.init(red: r/255, green: g/255, blue: b/255, alpha: 1)
    }
}
