//
//  UserPreferencesTableViewController.swift
//  Stepic
//
//  Created by Alexander Karpov on 24.09.15.
//  Copyright © 2015 Alex Karpov. All rights reserved.
//

import UIKit
import SVProgressHUD

class UserPreferencesTableViewController: UITableViewController {
    
    @IBOutlet weak var signInHeight: NSLayoutConstraint!
    @IBOutlet weak var signInNameDistance: NSLayoutConstraint!
    
    @IBOutlet weak var signInButton: UIButton!
    
    @IBOutlet weak var onlyWiFiSwitch: UISwitch!
    
    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var videoQualityLabel: UILabel!
    
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet weak var autoCheckForUpdatesLabel: UILabel!
    @IBOutlet weak var checkForUpdatesButton: UIButton!
    
    @IBOutlet weak var autoCheckForUpdatesSwitch: UISwitch!
    @IBOutlet weak var ignoreMuteSwitchLabel: UILabel!
    @IBOutlet weak var ignoreMuteSwitchSwitch: UISwitch!
    
    
    var heightForRows = [[131], [40, 0, 40], [40, 40], [40]]
    let selectionForRows = [[false], [false, false, true], [false, true], [true]]
    let sectionTitles = [
        NSLocalizedString("UserInfo", comment: ""),
        NSLocalizedString("Video", comment: ""),
        NSLocalizedString("Updates", comment: ""),
        NSLocalizedString("Actions", comment: "")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !StepicApplicationsInfo.inAppUpdatesAvailable {
            heightForRows[2] = [0, 0]
        }
        
        localize() 
        
        avatarImageView.setRoundedBounds(width: 0)
        
//        if let apiUser = AuthInfo.shared.user {
//            initWithUser(apiUser)
//        } else {
//            avatarImageView.image = Constants.placeholderImage
//        }
        
        signInButton.hidden = false
        onlyWiFiSwitch.on = !ConnectionHelper.shared.reachableOnWWAN
        ignoreMuteSwitchSwitch.on = AudioManager.sharedManager.ignoreMuteSwitch
        autoCheckForUpdatesSwitch.on = UpdatePreferencesContainer.sharedContainer.allowsUpdateChecks
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func updateUser() {
        if let user = AuthInfo.shared.user {
            self.initWithUser(user)
        } else {
            performRequest({
                if let user = AuthInfo.shared.user {
                    self.initWithUser(user)
                }
            })
        }
    }
    
    private func localize() {
        ignoreMuteSwitchLabel.text = NSLocalizedString("IgnoreMuteSwitch", comment: "")
        
        autoCheckForUpdatesLabel.text = NSLocalizedString("AutoCheckForUpdates", comment: "")
        checkForUpdatesButton.setTitle(NSLocalizedString("CheckForUpdates", comment: ""), forState: .Normal)
    }
    
    private func initWithUser(user : User) {
        avatarImageView.sd_setImageWithURL(NSURL(string: user.avatarURL), placeholderImage: Constants.placeholderImage)
        userNameLabel.text = "\(user.firstName) \(user.lastName)"
        if user.isGuest {
            signInHeight.constant = 30
            signInNameDistance.constant = 8
            heightForRows[0][0] = 131 + 38
            heightForRows[3][0] = 0
            signInButton.hidden = false
        } else {
            signInHeight.constant = 0
            signInNameDistance.constant = 0
            heightForRows[0][0] = 131
            heightForRows[3][0] = 40
            signInButton.hidden = true
        }
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        videoQualityLabel.text = "\(VideosInfo.videoQuality)p"
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
        updateUser()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CGFloat(heightForRows[indexPath.section][indexPath.row])
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return selectionForRows[indexPath.section][indexPath.row]
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.section == 3 && indexPath.row == 0 {
            signOut()
        }
        if indexPath.section  == 2 && indexPath.row == 1 {
            checkForUpdates()
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (!StepicApplicationsInfo.inAppUpdatesAvailable && section == 2) || (section == 3 && heightForRows[3][0] == 0) {
            return nil 
        } else {
            return sectionTitles[section]
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if !StepicApplicationsInfo.inAppUpdatesAvailable && section == 2 {
            return 0.1
        } else {
            return super.tableView(tableView, heightForHeaderInSection: section)
        }
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if !StepicApplicationsInfo.inAppUpdatesAvailable && section == 2 {
            return 0.1
        } else {
            return super.tableView(tableView, heightForFooterInSection: section)
        }
    }
    
    
    @IBAction func closeButtonPressed(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func printTokenButtonPressed(sender: UIButton) {
        print(AuthInfo.shared.token?.accessToken)
    }
    
    @IBAction func printDocumentsPathButtonPressed(sender: UIButton) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        print(documentsPath)
    }
    
    
    @IBAction func clearCacheButtonPressed(sender: UIButton) {
    }
    
    @IBAction func allow3GChanged(sender: UISwitch) {
        ConnectionHelper.shared.reachableOnWWAN = !sender.on
    }
    
    @IBAction func ignoreMuteSwitchChanged(sender: UISwitch) {
        AudioManager.sharedManager.ignoreMuteSwitch = sender.on
    }
    
    @IBAction func allowAutoUpdateChanged(sender: UISwitch) {
        UpdatePreferencesContainer.sharedContainer.allowsUpdateChecks = sender.on
    }
    
    func checkForUpdates() {
        RemoteVersionManager.sharedManager.checkRemoteVersionChange(needUpdateHandler:
            {
                [weak self]
                newVersion in
                if let version = newVersion {
                    let alert = VersionUpdateAlertConstructor.sharedConstructor.getUpdateAlertController(updateUrl: version.url, addNeverAskAction: false)
                    UIThread.performUI{
                        self?.presentViewController(alert, animated: true, completion: nil)
                    }
                } else {
                    let alert = VersionUpdateAlertConstructor.sharedConstructor.getNoUpdateAvailableAlertController()
                    UIThread.performUI{
                        self?.presentViewController(alert, animated: true, completion: nil)
                    }
                }
            }, error: {
                error in
                print("error while checking for updates: \(error.code) \(error.localizedDescription)")
        })
    }
    
    @IBAction func checkForUpdatesButtonPressed(sender: UIButton) {
        checkForUpdates()
    }
    
    func signOut() {
        AnalyticsReporter.reportEvent(AnalyticsEvents.Logout.clicked, parameters: nil)
        AuthInfo.shared.token = nil
        if let vc = ControllerHelper.getAuthController() as? AuthNavigationViewController {
            vc.success = {
                [weak self] in
                self?.updateUser()
            }
            vc.cancel = vc.success
            self.presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    func signIn() {
        if let vc = ControllerHelper.getAuthController() as? AuthNavigationViewController {
            vc.success = {
                [weak self] in
                self?.updateUser()
            }
            self.presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    @IBAction func signInButtonPressed(sender: AnyObject) {
        signIn()
    }
    
    @IBAction func signOutButtonPressed(sender: UIButton) {
        signOut()
    }
}
