//
//  AppDelegate+Trailhead.swift
//  SFSDKStarter
//
//  Created by Kevin Poorman on 9/24/19.
//  Copyright © 2019 Salesforce. All rights reserved.
//

import Foundation
import SalesforceSDKCore

extension AppDelegate {
    
    func initInstrumentation(){
        // listen for did show view controller notifications
        RestClient.swizzleSend()
        UITableView.swizzleDequeue()
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "UINavigationControllerDidShowViewControllerNotification"), object: nil, queue: nil) { (notification) in
            print("Recieved Notification of did show view controller")
            let previous = type(of: notification.userInfo?["UINavigationControllerLastVisibleViewController"] ?? "string")
            let next = type(of: notification.userInfo?["UINavigationControllerNextVisibleViewController"] ?? "string")

            let params = [
                "iosMiniHack1__type__c": "View Did Load",
                "iosMiniHack1__previous__c": "\(previous)",
                "iosMiniHack1__next__c": "\(next)"
            ]
            
            RestClient.shared.createInstrumentationRecord(params)
        }
       
        
    }

}
