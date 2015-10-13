//
//  SSHTunnel.swift
//  WeechatRelay
//
//  Created by Johan Lindskogen on 2015-09-28.
//  Copyright © 2015 Lindskogen. All rights reserved.
//

import Foundation
import SSHPortForward

public class SSHTunnel: NSObject {
    private static var isOpen: Bool = false
    private static var thread: NSThread!
    private static var delegate: SSHConnectionDelegate?
    
    public static var host: String = "127.0.0.1"
    public static var user: String = "user"
    public static var password: String = ""
    public static var port: Int32 = 9000
    public static var ssh_port: Int32 = 22
    
    public static func runThread() {
        guard !isOpen else {
            print("Port already opened")
            return
        }
        isOpen = true
        self.performSelectorInBackground("open", withObject: nil)
    }
    
    public static func setDelegate(delegate: SSHConnectionDelegate) {
        self.delegate = delegate
    }
    
    public static func open() {
        print("open()")
        let conn = SSHConnection()
        
        conn.connect(host, withPort: ssh_port)
        
        if let delegate = self.delegate {
            conn.delegate = delegate
        }
        
        let fingerprint = conn.fingerprint()
        print(fingerprint)
        
        let success = conn.authenticate(user, withPassword: password)
        
        let localPort: Int32 = 6001
        let localBind = "127.0.0.1"
        
        if success {
            conn.openPort(localBind, localPort: localPort, remoteBind: "localhost", andRemotePort: port)
        }
    }
}