//
//  RegistrationViewController.swift
//  Stepic
//
//  Created by Alexander Karpov on 18.12.15.
//  Copyright © 2015 Alex Karpov. All rights reserved.
//

import UIKit
import TextFieldEffects
import SVProgressHUD

class RegistrationViewController: UIViewController {
    
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var closeBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var firstNameTextField: HoshiTextField!
    
    @IBOutlet weak var lastNameTextField: HoshiTextField!
    
    @IBOutlet weak var emailTextField: HoshiTextField!
    
    @IBOutlet weak var passwordTextField: HoshiTextField!
    
    @IBOutlet weak var visiblePasswordButton: UIButton!
    
    @IBOutlet weak var firstNameErrorViewHeight: NSLayoutConstraint!
    @IBOutlet weak var lastNameErrorViewHeight: NSLayoutConstraint!
    @IBOutlet weak var emailErrorViewHeight: NSLayoutConstraint!
    @IBOutlet weak var passwordErrorViewHeight: NSLayoutConstraint!
    @IBOutlet weak var firstNameErrorLabel: UILabel!
    @IBOutlet weak var lastNameErrorLabel: UILabel!
    @IBOutlet weak var emailErrorLabel: UILabel!
    @IBOutlet weak var passwordErrorLabel: UILabel!
    
    var passwordSecure = false {
        didSet {
            visiblePasswordButton.setImage(passwordSecure ? Images.visibleImage : Images.visibleFilledImage, forState: UIControlState.Normal)
            passwordTextField.secureTextEntry = passwordSecure
        }
    }
    
    func setupLocalizations() {
        title = NSLocalizedString("SignUp", comment: "")
        firstNameTextField.placeholder = NSLocalizedString("FirstName", comment: "")
        lastNameTextField.placeholder = NSLocalizedString("LastName", comment: "")
        emailTextField.placeholder = NSLocalizedString("Email", comment: "")
        passwordTextField.placeholder = NSLocalizedString("Password", comment: "")
        signUpButton.setTitle(NSLocalizedString("SignUpAction", comment: ""), forState: .Normal)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        signUpButton.setRoundedCorners(cornerRadius: 8, borderWidth: 0, borderColor: UIColor.stepicGreenColor())
        
        setupLocalizations()
        firstNameTextField.autocapitalizationType = .Words
        lastNameTextField.autocapitalizationType = .Words
        
        emailTextField.autocapitalizationType = .None
        emailTextField.autocorrectionType = .No
        
        passwordTextField.delegate = self
        visiblePasswordButton.hidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func signUpPressed(sender: AnyObject) {
        signUpToStepic()
    }
    
    var success : (Void->Void)? {
        return (navigationController as? AuthNavigationViewController)?.success
    }
    
    func signUpToStepic() {
        let email = emailTextField.text ?? ""
        let firstName = firstNameTextField.text ?? ""
        let lastName = lastNameTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        
        SVProgressHUD.showWithStatus("", maskType: SVProgressHUDMaskType.Clear)
        performRequest({        
            AuthManager.sharedManager.signUpWith(firstName, lastname: lastName, email: email, password: password, success: {
                AuthManager.sharedManager.logInWithUsername(email, password: password, 
                    success: {
                        t in
                        AuthInfo.shared.token = t
                        NotificationRegistrator.sharedInstance.registerForRemoteNotifications(UIApplication.sharedApplication())
                        ApiDataDownloader.sharedDownloader.getCurrentUser({
                            user in
                            AuthInfo.shared.user = user
                            User.removeAllExcept(user)
                            SVProgressHUD.showSuccessWithStatus(NSLocalizedString("SignedIn", comment: ""))
                            UIThread.performUI { 
                                self.navigationController?.dismissViewControllerAnimated(true, completion: {
                                    [weak self] in
                                    self?.success?()
                                    })
                            }
                            AnalyticsHelper.sharedHelper.changeSignIn()
                            AnalyticsHelper.sharedHelper.sendSignedIn()
                            }, failure: {
                                e in
                                print("successfully signed in, but could not get user")
                                SVProgressHUD.showSuccessWithStatus(NSLocalizedString("SignedIn", comment: ""))
                                UIThread.performUI { 
                                    self.navigationController?.dismissViewControllerAnimated(true, completion: {
                                        [weak self] in
                                        self?.success?()
                                        })
                                }
                        })
                    }, failure: {
                        e in
                        SVProgressHUD.showErrorWithStatus(NSLocalizedString("FailedToSignIn", comment: ""))
                })
                }, error: {
                    errormsg, registrationErrorInfo in
                    //TODO: Add localized data
                    UIThread.performUI{SVProgressHUD.showErrorWithStatus(errormsg ?? NSLocalizedString("WrongFields", comment: "") )} 
                    if let info = registrationErrorInfo {
                        self.showEmailErrorWith(message: info.email)
                        self.showPasswordErrorWith(message: info.password)                    
                        self.showFirstNameErrorWith(message: info.firstName)
                        self.showLastNameErrorWith(message: info.lastName)
                    }
            })
            }, error: { 
                SVProgressHUD.showErrorWithStatus(NSLocalizedString("FailedToSignIn", comment: "")) 
        })
    }
    
    func showEmailErrorWith(message msg: String?) {
        changeHeightConstraint(emailErrorViewHeight, label: emailErrorLabel, text: msg)
    }
    func showPasswordErrorWith(message msg: String?) {
        changeHeightConstraint(passwordErrorViewHeight, label: passwordErrorLabel, text: msg)
    }
    func showFirstNameErrorWith(message msg: String?) {
        changeHeightConstraint(firstNameErrorViewHeight, label: firstNameErrorLabel, text: msg)
    }
    func showLastNameErrorWith(message msg: String?) {
        changeHeightConstraint(lastNameErrorViewHeight, label: lastNameErrorLabel, text: msg)
    }
    
    func changeHeightConstraint(constraint: NSLayoutConstraint, label: UILabel, text: String?) {
        if let msg = text {
            let height = UILabel.heightForLabelWithText(msg, lines: 0, standardFontOfSize: 12, width: UIScreen.mainScreen().bounds.width - 32)
            label.text = msg
            animateConstraintChange(constraint, value: height)
        } else {
            animateConstraintChange(constraint, value: 0)
        }
    }
    func animateConstraintChange(constraint: NSLayoutConstraint, value: CGFloat) {
        constraint.constant = value
        UIView.animateWithDuration(0.25) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func visiblePasswordButtonPressed(sender: AnyObject) {
        passwordSecure = !passwordSecure
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}

extension RegistrationViewController : UITextFieldDelegate {
    func textFieldDidBeginEditing(textField: UITextField) {
        print("did begin")
        passwordSecure = true
        if textField == passwordTextField {
            visiblePasswordButton.hidden = false
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        print("did end")
        passwordSecure = true
        if textField == passwordTextField && textField.text == "" {
            visiblePasswordButton.hidden = true
        }
    }    
}
