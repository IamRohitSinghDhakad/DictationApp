//
//  WatchConnectivityManager.swift
//  DictationApp
//
//  Created by Dhakad on 08/06/23.
//

import Foundation
import WatchConnectivity

struct NotificationMessage: Identifiable{
    let id = UUID()
    let file : WCSessionFile
    let message : String
    let userInfo : [String : Any]
}

final class WatchConnectivityManager: NSObject, ObservableObject {
    
    static let shared = WatchConnectivityManager()
    public let session = WCSession.default
    @Published var notificationMessage: NotificationMessage? = nil
    @Published var isWatchConnected: Bool = false
    private let kMessageKey = "message"
    
    private override init() {
        super.init()
        
        /// Check if WCSession is supported on the current device
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
            isWatchConnected = true
        }else{
            isWatchConnected = false
        }
    }
    
    /// Function to handle session reachability changes
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = session.isReachable
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate{
    
    /// Function to handle receiving messages from the Watch or iPhone
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
          if let notificationText = message[kMessageKey] as? String {
              DispatchQueue.main.async { [weak self] in
                  self?.notificationMessage = NotificationMessage(file: WCSessionFile(), message: notificationText, userInfo: [:])
              }
          }
      }
    
    /// Function to handle receiving user info from the Watch or iPhone
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
            DispatchQueue.main.async {
                self.notificationMessage = NotificationMessage(file: WCSessionFile(), message: "", userInfo: userInfo)
            }
    }
    
    /// Function to handle receiving files from the Watch or iPhone
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        print(file.fileURL)
        DispatchQueue.main.async {
            self.notificationMessage = NotificationMessage(file: file, message: "", userInfo: [:])
        }
    }
    
    /// Function to handle session activation completion
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}
    
    ///These Line activates a session in case it gets deactivated. This can happen if the user owns several watches and we need to support watch switching.
#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
#endif
    
}

extension WatchConnectivityManager{
    ///Function to send data to the iPhone
    public func sendDataToPhone(_ user:UserAudioData) {
        let dict:[String:Any] = ["data":user.encodeIt()]
        
        guard session.activationState == .activated else {
            return
        }
#if os(iOS)
        guard WCSession.default.isWatchAppInstalled else {
            return
        }
#else
        guard WCSession.default.isCompanionAppInstalled else {
            return
        }
#endif
        session.transferUserInfo(dict)

    }
    

    
    public func sendFileUrlToPhone(file: URL, metaData : [String : Any]) {
        print(file)
        
        guard session.activationState == .activated else {
            return
        }
#if os(iOS)
        guard WCSession.default.isWatchAppInstalled else {
            return
        }
#else
        guard WCSession.default.isCompanionAppInstalled else {
            return
        }
#endif
        session.transferFile(file, metadata: nil)

    }
    
    ///Function to send data to the watch
    func send(_ message: String) {
        guard WCSession.default.activationState == .activated else {
          return
        }
        #if os(iOS)
        guard WCSession.default.isWatchAppInstalled else {
            return
        }
        #else
        guard WCSession.default.isCompanionAppInstalled else {
            return
        }
        #endif
        
        WCSession.default.sendMessage([kMessageKey : message], replyHandler: nil) { error in
            print("Cannot send message: \(String(describing: error))")
        }
    }
    
    

}
