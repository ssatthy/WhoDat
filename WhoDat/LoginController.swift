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
    
    let defaultProfilePicture = UIImage(named: "profilepic")
    
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
        button.backgroundColor = UIColor.lightGray
        button.setTitle("Login", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = false
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
        email.placeholder = "Phone: +65 1234 5678"
        email.translatesAutoresizingMaskIntoConstraints = false
        email.keyboardType = UIKeyboardType.phonePad
        return email
    }()

    lazy var profilePictureView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = defaultProfilePicture
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 75
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleProfilePicture)))
        imageView.isUserInteractionEnabled = true
        
        return imageView
    }()
    
    lazy var profileRedBorderView: UIView = {
       let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.red
        view.layer.cornerRadius = 91
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var profileGreenBorderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(r: 0, g: 204, b: 0)
        view.layer.cornerRadius = 83
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var terms: UILabel = {
        let label = UILabel()
        label.text = "I accept the terms & conditions."
        label.textColor = UIColor.gray
        label.font = label.font.withSize(12)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToTerms)))
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let checkbox: Checkbox = {
       let checkbox = Checkbox()
        checkbox.checkedBorderColor = .gray
        checkbox.uncheckedBorderColor = .gray
        checkbox.borderStyle = .circle
        checkbox.checkmarkColor = .gray
        checkbox.checkmarkStyle = .tick
        checkbox.useHapticFeedback = true
        checkbox.addTarget(self, action: #selector(checkboxValueChanged(sender:)), for: .valueChanged)
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        return checkbox
    }()
    
    
    @objc func checkboxValueChanged(sender: Checkbox) {
        if sender.isChecked {
            loginButton.backgroundColor = .gray
            loginButton.isUserInteractionEnabled = true
        } else {
            loginButton.isUserInteractionEnabled = false
            loginButton.backgroundColor = .lightGray
        }
    }
    
    @objc func goToTerms() {
        UIApplication.shared.open(URL(string: "http://www.likethatalsocan.com/end-user-license-agreement/")!, options: [:], completionHandler: nil)
        
    }

    @objc func handleLogin() {
        
        if phoneField.text == nil || nameField.text == nil || profilePictureView.image!.isEqual(defaultProfilePicture) {
            let validateAlert = UIAlertController(title: "Invalid Inputs", message: "Profile picture, name and phone are required!", preferredStyle: .alert)
            let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
            validateAlert.addAction(ok)
            present(validateAlert, animated: true, completion: nil)
            return
        }
        
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
        
        view.backgroundColor = UIColor(r: 255, g: 255, b: 255)
        self.hideKeyboardWhenTappedAround()
        view.addSubview(inputsContainerView)
        view.addSubview(loginButton)
        view.addSubview(profileRedBorderView)
        view.addSubview(profileGreenBorderView)
        view.addSubview(profilePictureView)
        view.addSubview(terms)
        view.addSubview(checkbox)
        
        setupInputsContainerView()
        setupProfilePicture()

    }
    
    func setupProfilePicture() {
        
        profilePictureView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        profilePictureView.bottomAnchor.constraint(equalTo: inputsContainerView.topAnchor, constant: -18).isActive = true
        profilePictureView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        profilePictureView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        
        profileRedBorderView.centerXAnchor.constraint(equalTo: profilePictureView.centerXAnchor).isActive = true
        profileRedBorderView.centerYAnchor.constraint(equalTo: profilePictureView.centerYAnchor).isActive = true
        profileRedBorderView.widthAnchor.constraint(equalToConstant: 182).isActive = true
        profileRedBorderView.heightAnchor.constraint(equalToConstant: 182).isActive = true
        
        profileGreenBorderView.centerXAnchor.constraint(equalTo: profilePictureView.centerXAnchor).isActive = true
        profileGreenBorderView.centerYAnchor.constraint(equalTo: profilePictureView.centerYAnchor).isActive = true
        profileGreenBorderView.widthAnchor.constraint(equalToConstant: 166).isActive = true
        profileGreenBorderView.heightAnchor.constraint(equalToConstant: 166).isActive = true
        
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
        
        checkbox.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        checkbox.topAnchor.constraint(equalTo: inputsContainerView.bottomAnchor, constant: 5).isActive = true
        checkbox.widthAnchor.constraint(equalToConstant: 20).isActive = true
        checkbox.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        terms.leftAnchor.constraint(equalTo: checkbox.rightAnchor, constant: 12).isActive = true
        terms.topAnchor.constraint(equalTo: inputsContainerView.bottomAnchor, constant: 5).isActive = true
        terms.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        terms.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginButton.topAnchor.constraint(equalTo: terms.bottomAnchor, constant: 15).isActive = true
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
