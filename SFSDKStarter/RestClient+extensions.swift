//
//  RestClient+attachments.swift
//  SFSDKStarter
//
//  Created by Kevin Poorman on 7/11/19.
//  Copyright © 2019 Salesforce. All rights reserved.
//

import Foundation
import SalesforceSDKCore
import UIKit

extension RestClient {
    
    func requestForCreatingImageAttachment(from image: UIImage, relatingTo: String, fileName: String? = nil) -> RestRequest {
        let imageData = UIImagePNGRepresentation(image)!
        let uploadFileName = fileName ?? UUID().uuidString + ".png"
        return self.requestForCreatingAttachment(from: imageData, withFileName: uploadFileName, relatingTo: relatingTo)
    }
    
    private func requestForCreatingAttachment(from data: Data, withFileName fileName: String, relatingTo: String) -> RestRequest {
        let record = ["VersionData": data.base64EncodedString(options: .lineLength64Characters), "Title": fileName, "PathOnClient": fileName, "FirstPublishLocationId": relatingTo]
        return self.requestForCreate(withObjectType: "ContentVersion", fields: record)
    }
    
    @objc func sendWithInstrumentation(request: RestRequest, onFailure: @escaping (RestFailBlock), onSuccess: @escaping (RestResponseBlock) ) {
        print("Swizzled")
        RestClient.shared.sendWithInstrumentation(request: request, onFailure: onFailure, onSuccess: onSuccess)
    }
    
    private static let swizzleSendImplementation: Void = {
        let instance: RestClient = RestClient.shared
        let klass: AnyClass! = object_getClass(instance)
        let originalMethod = class_getInstanceMethod(klass, #selector(send(request:onFailure:onSuccess:)))
        let swizzledMethod = class_getInstanceMethod(klass, #selector(sendWithInstrumentation(request:onFailure:onSuccess:)))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }()
    
    public static func swizzleSend() {
        _ = self.swizzleSendImplementation
    }
}
