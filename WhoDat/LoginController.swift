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
    
    var mode: Bool = true
    
    
    let inputsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var loginRegisterButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(r: 80, g: 101, b: 161)
        button.setTitle("Login", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.addTarget(self, action: #selector(handleLoginRegister), for: .touchUpInside)
        
        return button
    }()
    
    lazy var newAccountLink: UILabel = {
        let label = UILabel()
        label.text = "Register?"
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textAlignment = .right
        label.textColor = UIColor.white
        label.isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleNewAccount))
        label.addGestureRecognizer(tap)
        
        return label
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
    
    let emailField: UITextField = {
        let email = UITextField()
        email.placeholder = "Email"
        email.translatesAutoresizingMaskIntoConstraints = false
        return email
    }()
    
    let emailSeparator: UIView = {
        let separator = UIView()
        separator.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        separator.translatesAutoresizingMaskIntoConstraints = false
        return separator
    }()

    let passwordField: UITextField = {
        let password = UITextField()
        password.placeholder = "Password"
        password.isSecureTextEntry = true
        password.translatesAutoresizingMaskIntoConstraints = false
        return password
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
    

    func handleNewAccount() {
        mode = !mode
        newAccountLink.text = mode ? "Register?" : "Login?"
        handleLoginRegisterChange()
    }
    
    func handleLoginRegisterChange() {
        
        loginRegisterButton.setTitle(mode ? "Login" : "Register" , for: .normal)
        
        inputsContainerViewHeighAnchor?.constant = mode ? 100 : 150
        
        nameFieldHeightAnchor?.isActive = false
        nameFieldHeightAnchor = nameField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: mode ? 0 : 1/3)
        nameFieldHeightAnchor?.isActive = true
        nameField.isHidden = mode
        
        emailFieldHeightAnchor?.isActive = false
        emailFieldHeightAnchor = emailField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: mode ? 1/2 : 1/3)
        emailFieldHeightAnchor?.isActive = true
        
        passwordFieldHeightAnchor?.isActive = false
        passwordFieldHeightAnchor = passwordField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: mode ? 1/2 : 1/3)
        passwordFieldHeightAnchor?.isActive = true
        
    }
    func handleLoginRegister() {
        if mode {
            hanleLogin()
        } else {
            handleRegister()
        }
    }
    
    func hanleLogin() {
        guard let email = emailField.text, let password = passwordField.text
            else {
                print("Invalid form inputs!")
                return
        }
        
        Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
            if error != nil {
                print(error ?? "Signin failed")
                return
            }
            self.messageController?.fetchUserAndSetNavBar()
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(r: 61, g: 91, b: 151)
        
        view.addSubview(inputsContainerView)
        view.addSubview(loginRegisterButton)
        view.addSubview(profilePictureView)
        view.addSubview(newAccountLink)
        
        setupInputsContainerView()
        setupLoginRegiterSetup()
        setupProfilePicture()

    }
    
    func setupProfilePicture() {
        profilePictureView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        profilePictureView.bottomAnchor.constraint(equalTo: inputsContainerView.topAnchor, constant: -12).isActive = true
        profilePictureView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        profilePictureView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        
    }
    
    var inputsContainerViewHeighAnchor: NSLayoutConstraint?
    var nameFieldHeightAnchor: NSLayoutConstraint?
    var emailFieldHeightAnchor: NSLayoutConstraint?
    var passwordFieldHeightAnchor: NSLayoutConstraint?
    
    func setupInputsContainerView() {

        inputsContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        inputsContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        inputsContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        inputsContainerViewHeighAnchor = inputsContainerView.heightAnchor.constraint(equalToConstant: 100)
        inputsContainerViewHeighAnchor?.isActive = true
        
        inputsContainerView.addSubview(nameField)
        nameField.topAnchor.constraint(equalTo: inputsContainerView.topAnchor).isActive = true
        nameField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        nameField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        nameFieldHeightAnchor = nameField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 0)
        nameFieldHeightAnchor?.isActive = true
        nameField.isHidden = mode
        
        inputsContainerView.addSubview(nameSeparator)
        
        nameSeparator.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor).isActive = true
        nameSeparator.topAnchor.constraint(equalTo: nameField.bottomAnchor).isActive = true
        nameSeparator.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        nameSeparator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        inputsContainerView.addSubview(emailField)
        emailField.topAnchor.constraint(equalTo: nameField.bottomAnchor).isActive = true
        emailField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        emailField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        emailFieldHeightAnchor = emailField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/2)
        emailFieldHeightAnchor?.isActive = true
        
        inputsContainerView.addSubview(emailSeparator)
        emailSeparator.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor).isActive = true
        emailSeparator.topAnchor.constraint(equalTo: emailField.bottomAnchor).isActive = true
        emailSeparator.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        emailSeparator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        inputsContainerView.addSubview(passwordField)
        passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor).isActive = true
        passwordField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        passwordField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        passwordFieldHeightAnchor = passwordField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/2)
        passwordFieldHeightAnchor?.isActive = true
        
    }
    
    func setupLoginRegiterSetup() {
        loginRegisterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginRegisterButton.topAnchor.constraint(equalTo: inputsContainerView.bottomAnchor, constant: 12).isActive = true
        loginRegisterButton.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        loginRegisterButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        
        newAccountLink.rightAnchor.constraint(equalTo: inputsContainerView.rightAnchor).isActive = true
        newAccountLink.topAnchor.constraint(equalTo: loginRegisterButton.bottomAnchor).isActive = true
        newAccountLink.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor, multiplier: 1/3).isActive = true
        newAccountLink.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
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
