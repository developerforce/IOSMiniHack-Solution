//
//  TableView+Instrumentation.swift
//  SFSDKStarter
//
//  Created by Kevin Poorman on 9/25/19.
//  Copyright © 2019 Salesforce. All rights reserved.
//

import Foundation
import UIKit
import SalesforceSDKCore

extension UITableView {
    
    @objc func dequeueReusuableCellWithInstrumentation(withIdentifier: String) -> UITableViewCell {
        let params = [
            "iosMiniHack1__type__c": "Cell Drawn"
        ]
        RestClient.shared.createInstrumentationRecord(params)
        return dequeueReusuableCellWithInstrumentation(withIdentifier: withIdentifier)
    }
    
    private static let swizzleDequeuedImplementation: Void = {
        let instance: UITableView = UITableView()
        let klass: AnyClass! = object_getClass(instance)
        let originalMethod = class_getInstanceMethod(klass, #selector(dequeueReusableCell(withIdentifier:)))
        let swizzledMethod = class_getInstanceMethod(klass, #selector(dequeueReusuableCellWithInstrumentation(withIdentifier:)))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }()
    
    public static func swizzleDequeue() {
        _ = self.swizzleDequeuedImplementation
    }
    
}
