//
//  ViewController.swift
//  VPN
//
//  Created by ly on 2017/10/17.
//  Copyright © 2017年 LY. All rights reserved.
//

import UIKit
import NetworkExtension

class ViewController: UIViewController,UITextFieldDelegate {

    @IBOutlet weak var vpnServerAddress: UITextField!
    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var password: UITextField!
    
    var ikev2 : IKEv2?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        vpnServerAddress.delegate = self
        userName.delegate = self
        password.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

  
    @IBAction func configurationVPN(_ sender: UIButton) {
        ikev2 = IKEv2(userName: userName.text!, serverAddress: vpnServerAddress.text!, password: password.text!, sharedPassword: userName.text!, localIdentifier: "", remoteIdentifier: vpnServerAddress.text!, localizedDescription: "VPN-TEST")
        ikev2?.configurationVPNProtocol()
    }
    
    @IBAction func startConnect(_ sender: UIButton) {
        if (ikev2?.startConnect())! {
            debugPrint("开启成功")
        } else {
            debugPrint("开启失败")
        }
    }
    
    @IBAction func disConnect(_ sender: UIButton) {
        if (ikev2?.disConnect())! {
            debugPrint("断开成功")
        } else {
            debugPrint("断开失败")
        }
    }
    
    @IBAction func removeVPN(_ sender: UIButton) {
        _ = ikev2?.removeVPN()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}

