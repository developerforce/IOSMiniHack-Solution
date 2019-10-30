//
//  ContactDetailSceneController.swift
//  SFSDKStarter
//
//  Created by Kevin Poorman on 7/11/19.
//  Copyright © 2019 Salesforce. All rights reserved.
//

import Foundation
import UIKit
import SalesforceSDKCore

class ContactDetailsSceneController: UITableViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    let fieldBlacklist = ["attributes", "Id"]
    var contactId: String?
    var imagePickerCtrl: UIImagePickerController!
    var name: String?
    var dataRows = [ObjectField]()
    typealias ObjectField = (label: String, value: String)

    // MARK: - View lifecycle
    override func loadView() {
        super.loadView()
        guard let contactId = self.contactId else { return }
        let fieldList = "Id, Name, Email, Phone, MailingStreet, MailingCity, MailingState, MailingPostalCode"
        let dataRequest = RestClient.shared.requestForRetrieve(withObjectType: "Contact", objectId: contactId, fieldList: fieldList)
        
        RestClient.shared.send(request: dataRequest, onFailure: { (error, urlResponse) in
            SalesforceLogger.d(type(of:self), message:"Error invoking: \(dataRequest)")
        }) { [weak self] (response, urlResponse) in
            var resultsToReturn = [ObjectField]()
            guard let strongSelf = self else { return }
            
            SalesforceLogger.d(type(of:strongSelf),message:"Invoked: \(dataRequest)")
            if let dictionaryResponse = response as? [String: Any] {
                resultsToReturn = strongSelf.fields(from: dictionaryResponse)
            }
            
            DispatchQueue.main.async {
                strongSelf.dataRows = resultsToReturn
                strongSelf.tableView.reloadData()
            }
        }
    }
    
    /// Transforms the fields in the record into `ObjectField` values, omitting
    /// any fields that are in the blacklist or that are not strings.
    ///
    /// - Parameter record: The record to be transformed.
    /// - Returns: The list of object fields extracted from the record.
    private func fields(from record: [String: Any]) -> [ObjectField] {
        let filteredRecord = record.lazy.filter { key, value in !self.fieldBlacklist.contains(key) && value is String }
        return filteredRecord.map { key, value in (label: key, value: value as! String) }
    }
    
    // MARK: - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
        return self.dataRows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "ContactFieldIdentifier"
        
        // Dequeue or create a cell of the appropriate type.
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier:cellIdentifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        
        
        // Configure the cell to show the data.
        let obj = dataRows[indexPath.row]
        cell.textLabel?.text = obj.value
        
        cell.detailTextLabel?.text = obj.label
        
        // This adds the arrow to the right hand side.
        return cell
    }
    
    @IBAction func didTapPhotoButton(_ sender: Any){
        imagePickerCtrl = UIImagePickerController()
        imagePickerCtrl.delegate = self
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePickerCtrl.sourceType = .camera
        } else {
            // Device camera is not available. Use photo album instead.
            imagePickerCtrl.sourceType = .savedPhotosAlbum
        }
        
        present(imagePickerCtrl, animated: true, completion: nil)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imagePickerCtrl.dismiss(animated: true, completion: nil)
        // Make sure to leave this line intact. It helps us score the challenge
        RestClient.shared.sendImagesSelectedInstrumentation()
        if let image = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            guard let contactId = self.contactId else {return}
            let attachmentRequest = RestClient.shared.requestForCreatingImageAttachment(from: image, relatingTo: contactId)
            RestClient.shared.send(request: attachmentRequest, onFailure: self.handleError){ result, _ in
                SalesforceLogger.d(type(of: self), message: "Completed upload of photo")
            }
        }
    }
    
    private func handleError(_ error: Error?, urlResponse: URLResponse? = nil) {
        let errorDescription: String
        if let error = error {
            errorDescription = "\(error)"
        } else {
            errorDescription = "An unknown error occurred."
        }
        
        SalesforceLogger.e(type(of: self), message: "Failed to successfully complete the REST request. \(errorDescription)")
    }
}
