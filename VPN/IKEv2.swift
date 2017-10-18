//
//  File.swift
//  VPN
//
//  Created by ly on 2017/10/17.
//  Copyright © 2017年 LY. All rights reserved.
//

import Foundation
import NetworkExtension

class IKEv2 {
    
    let userName : String
    let serverAddress : String
    let password : String
    let sharedPassword : String
    let localIdentifier : String
    let remoteIdentifier : String
    let localizedDescription : String
    var vpnManager : NEVPNManager = NEVPNManager.shared()
    init(userName:String,serverAddress:String,password:String,sharedPassword:String,localIdentifier:String,remoteIdentifier:String,localizedDescription:String) {
        self.userName = userName    //用户名
        self.serverAddress = serverAddress  //服务器地址
        self.password = password    //密码
        self.sharedPassword = sharedPassword    //共享密码，可与密码一样
        self.localIdentifier = localIdentifier  //本地IP
        self.remoteIdentifier = remoteIdentifier    //服务器IP
        self.localizedDescription = localizedDescription    //VPN名字
    }
    
    func configurationVPNProtocol() {
        // authenticationMethod 认证模式
        // useExtendedAuthentication 是否协商扩展认证
        // disconnectOnSleep 睡眠时断开
        // isOnDemandEnabled 按需功能切换连接
        // isEnabled 用于切换VPN配置的启用状态
        vpnManager.loadFromPreferences(completionHandler: {(error:Error?) -> Void in
            guard (error == nil) else {
                debugPrint(error.debugDescription + "加载配置出错")
                return
            }
            let p = NEVPNProtocolIKEv2()
            p.username = self.userName
            p.serverAddress = self.serverAddress
            guard self.createKeychainValue(password: self.password, forIdentifier: "vpnPassword") else {
                debugPrint("createKeychainValue创建钥匙串失败")
                return
            }
            p.passwordReference = self.searchKeychainCopyMatching(identifier: "vpnPassword")
            guard self.createKeychainValue(password: self.sharedPassword, forIdentifier: "sharedPassword") else {
                debugPrint("createKeychainValue创建共享钥匙串失败")
                return
            }
            p.sharedSecretReference = self.searchKeychainCopyMatching(identifier: "sharedPassword")
            p.localIdentifier = self.localIdentifier
            p.remoteIdentifier = self.remoteIdentifier
            p.authenticationMethod = .certificate
            p.useExtendedAuthentication = true
            p.disconnectOnSleep = false
            self.self.vpnManager.protocolConfiguration = p
            self.vpnManager.isOnDemandEnabled = false
            self.vpnManager.localizedDescription = self.localizedDescription
            self.vpnManager.isEnabled = true
            self.vpnManager.saveToPreferences(completionHandler: {(errors:Error?) -> Void in
                guard errors == nil else {
                    debugPrint(errors.debugDescription + "保存配置出错")
                    return
                }
                debugPrint("Saved")
            })
        })
        //注册到通知中心，监视者
        NotificationCenter.default.addObserver(self, selector: #selector(onVpnStateChange), name: NSNotification.Name.NEVPNStatusDidChange, object: nil)
    }
    
    func newSearchDictionary(identifier:String) -> NSMutableDictionary {
        //   extern CFTypeRef kSecClassGenericPassword  一般密码
        //   extern CFTypeRef kSecClassInternetPassword 网络密码
        //   extern CFTypeRef kSecClassCertificate 证书
        //   extern CFTypeRef kSecClassKey 秘钥
        //   extern CFTypeRef kSecClassIdentity 带秘钥的证书
        //   kSecAttrGeneric 表示该项目的用户定义的属性
        //   kSecAttrAccount 表示该项目的帐户名称
        //   kSecAttrService 表示该项目的服务
        let searchDictionary : NSMutableDictionary = [:]
        searchDictionary.setObject(kSecClassGenericPassword, forKey: kSecClass as! NSCopying)
        let encodedIdentifier = identifier.data(using: .utf8)
        searchDictionary.setObject(encodedIdentifier!, forKey: kSecAttrGeneric as! NSCopying)
        searchDictionary.setObject(encodedIdentifier!, forKey: kSecAttrAccount as! NSCopying)
        searchDictionary.setObject(serverAddress, forKey: kSecAttrService as! NSCopying)
        return searchDictionary
    }
    
    func createKeychainValue(password:String,forIdentifier identifier:String) -> Bool {
        // SecItemDelete 删除与搜索查询匹配的项目,默认情况下，该功能删除与指定查询匹配的所有项
        // SecItemAdd 将一个或多个项目添加到钥匙扣
        // kSecValueData 对于密钥和密码项，数据是加密的，可能需要用户输入密码进行访问
        let dictionary = newSearchDictionary(identifier: identifier)
        var status = SecItemDelete(dictionary)
        let passwordData = password.data(using: .utf8)
        dictionary.setObject(passwordData!, forKey: kSecValueData as! NSCopying)
        status = SecItemAdd(dictionary, nil)
        if status == errSecSuccess {
            return true
        }
        return false
    }
    
    func searchKeychainCopyMatching(identifier:String) -> Data {
        // kSecMatchLimit 如果提供，则该值指定要返回或以其他方式执行的最大结果数。 对于单个项目，请指定kSecMatchLimitOne。 要指定所有匹配的项目，请指定kSecMatchLimitAll。
        // kSecReturnPersistentRef 表示是否返回对项目的持久引用
        // SecItemCopyMatching 返回与搜索查询匹配的一个或多个钥匙串项，或复制特定钥匙串项的属性。默认情况下，此函数仅返回找到的第一个匹配项。要一次获得多个匹配的项目，请指定大于1的值的搜索关键字kSecMatchLimit。
        let searchDictionary = newSearchDictionary(identifier: identifier)
        searchDictionary.setObject(kSecMatchLimitOne, forKey: kSecMatchLimit as! NSCopying)
        searchDictionary.setObject(true, forKey: kSecReturnPersistentRef as! NSCopying)
        var result : CFTypeRef?
        SecItemCopyMatching(searchDictionary, &result)
        return result as! Data
    }
    
    @objc func onVpnStateChange(notification:Notification) {
        let state = vpnManager.connection.status
        switch state {
        case .invalid:
            debugPrint("无效VPN")
        case .disconnected:
            debugPrint("已断开连接")
        case .connecting:
            debugPrint("正在连接")
        case .connected:
            debugPrint("已连接")
        case .reasserting:
            debugPrint("重新连接")
        case .disconnecting:
            debugPrint("正在断开连接")
        }
    }
    
    func startConnect() -> Bool {
            do  {
                try vpnManager.connection.startVPNTunnel()
                return true
            } catch {
                debugPrint(error.localizedDescription)
                return false
            }
    }
    
    func disConnect() -> Bool {
        vpnManager.connection.stopVPNTunnel()
        return true
    }
    
    func removeVPN() -> Bool {
        vpnManager.removeFromPreferences(completionHandler: {(error:Error?) -> Void in
            guard error == nil else {
                debugPrint(error.debugDescription)
                return
            }
            debugPrint("删除成功")
        })
        return true
    }
}
