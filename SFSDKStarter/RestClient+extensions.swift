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
        let resized = image.resized(toPercentage: 0.25)
        let imageData = UIImagePNGRepresentation(resized)!
        let uploadFileName = fileName ?? UUID().uuidString + ".png"
        return self.requestForCreatingAttachment(from: imageData, withFileName: uploadFileName, relatingTo: relatingTo)
    }
    
    private func requestForCreatingAttachment(from data: Data, withFileName fileName: String, relatingTo: String) -> RestRequest {
        let record = ["VersionData": data.base64EncodedString(options: .lineLength64Characters), "Title": fileName, "PathOnClient": fileName, "FirstPublishLocationId": relatingTo]
        return self.requestForCreate(withObjectType: "ContentVersion", fields: record)
    }
    
    func createInstrumentationRecord(_ params: [String:String]){
        let instrumentationRequest = RestClient.shared.requestForCreate(withObjectType: "iosMiniHack1__instrumentation__c", fields: params)
        
        RestClient.shared.sendWithInstrumentation(request: instrumentationRequest, onFailure: { (error, urlResponse) in
            SalesforceLogger.d(type(of:self), message:"Error invoking: \(instrumentationRequest). Error is: \(String(describing: error))")
        }) { [weak self] (response, urlResponse) in
            if let strongSelf = self {
                SalesforceLogger.d(type(of:strongSelf), message:"Invoked instrumentationRequest")
            }
        }
    }
    
    func sendImagesSelectedInstrumentation() {
        RestClient.shared.createInstrumentationRecord(["iosMiniHack1__type__c":"Images Selected"])
    }
    
    @objc func sendWithInstrumentation(request: RestRequest, onFailure: @escaping (RestFailBlock), onSuccess: @escaping (RestResponseBlock) ) {
        var params = [
            "iosMiniHack1__type__c": "RestClient Query",
            "iosMinihack1__Endpoint__c": request.endpoint,
            "iosMinihack1__Method__c" : "\(request.method.rawValue)",
            "iosMinihack1__Path__c" : request.path
        ]
        
        if let data = request.queryParams {
            if let q = data.value(forKey: "q") as? String {
                params["iosMiniHack1__query__c"] = q
            }
            
            if let fields = data.value(forKey: "fields") as? String {
                params["iosMiniHack1__query__c"] = fields
            }
        }
        
        createInstrumentationRecord(params)
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
