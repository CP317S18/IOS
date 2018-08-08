//
//  SettingsViewController.swift
//  shout
//
//  Created by Greg Murray on 2018-07-05.
//  Copyright © 2018 wlu. All rights reserved.
//

import Foundation
import UIKit

class SettingsViewController: UITableViewController{
    @IBOutlet var settingsTableView: UITableView!
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.settingsTableView.contentInset = UIEdgeInsets(top: UIApplication.shared.statusBarFrame.height, left: 0, bottom: 0, right: 0)
    }
}


class NotificationSettingsView: UITableViewController{
    let userDefaults = UserDefaults.standard
    
    @IBOutlet weak var showNotifSwitch: UISwitch!
    @IBOutlet weak var soundSwitch: UISwitch!
    @IBOutlet weak var vibrateSwitch: UISwitch!
    
    
    @IBAction func switchNotifs(_ sender: UISwitch) {
        userDefaults.set(showNotifSwitch.isOn, forKey: "NotificationsActive")
    }
    
    @IBAction func switchSound(_ sender: Any) {
        userDefaults.set(soundSwitch.isOn, forKey: "SoundActive")
    }
    @IBAction func switchVibrate(_ sender: Any) {
        userDefaults.set(vibrateSwitch.isOn, forKey: "VibrateActive")
    }
    
    @IBAction func resetNotifications(_ sender: Any) {
        userDefaults.set(true, forKey: "NotificationsActive")
        userDefaults.set(true, forKey: "SoundActive")
        userDefaults.set(true, forKey: "VibrateActive")
        showNotifSwitch.setOn(true, animated: true)
        soundSwitch.setOn(true, animated: true)
        vibrateSwitch.setOn(true, animated: true)
    }
    
    @IBOutlet var notificationsTableView: UITableView!
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.notificationsTableView.contentInset = UIEdgeInsets(top: UIApplication.shared.statusBarFrame.height, left: 0, bottom: 0, right: 0)
        showNotifSwitch.setOn(userDefaults.bool(forKey: "NotificationsActive"), animated: false)
        soundSwitch.setOn(userDefaults.bool(forKey: "SoundActive"), animated: false)
        vibrateSwitch.setOn(userDefaults.bool(forKey: "VibrateActive"), animated: false)
        
    }
}

class ReportBugsView: UITableViewController{
    
    @IBOutlet var reportBugsTable: UITableView!
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.reportBugsTable.contentInset = UIEdgeInsets(top: UIApplication.shared.statusBarFrame.height, left: 0, bottom: 0, right: 0)
    }
}
