//
//  ContactsSceneController.swift
//  SFSDKStarter
//
//  Created by Kevin Poorman on 7/11/19.
//  Copyright © 2019 Salesforce. All rights reserved.
//

import Foundation
import UIKit
import SalesforceSDKCore

class ContactsSceneController: UITableViewController {
    var accountId: String?
    var name: String?
    var dataRows = [Dictionary<String, Any>]()
    
    // MARK: - View lifecycle
    override func loadView() {
        super.loadView()
        guard let aid = self.accountId else {return}
        let request = RestClient.shared.request(forQuery: "SELECT Id, Name FROM Contact WHERE accountid = '\(aid)' LIMIT 10")
        if let name = self.name {
            self.title = name + "'s Contacts"
        } else {
            self.title = "Contacts"
        }
        RestClient.shared.send(request: request, onFailure: { (error, urlResponse) in
            SalesforceLogger.d(type(of:self), message:"Error invoking: \(request)")
        }) { [weak self] (response, urlResponse) in
            
            guard let strongSelf = self,
                let jsonResponse = response as? Dictionary<String,Any>,
                let result = jsonResponse ["records"] as? [Dictionary<String,Any>]  else {
                    return
            }
            
            SalesforceLogger.d(type(of:strongSelf),message:"Invoked: \(request)")
            
            DispatchQueue.main.async {
                strongSelf.dataRows = result
                strongSelf.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
        return self.dataRows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "ContactNamePrototypeCell"
        
        // Dequeue or create a cell of the appropriate type.
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier:cellIdentifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        
        // If you want to add an image to your cell, here's how.
        let image = UIImage(named: "icon.png")
        cell.imageView?.image = image
        
        // Configure the cell to show the data.
        let obj = dataRows[indexPath.row]
        cell.textLabel?.text = obj["Name"] as? String
        
        // This adds the arrow to the right hand side.
        cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toContactDetailController" {
            let destination = segue.destination as! ContactDetailsSceneController
            let cell = sender as! UITableViewCell
            let indexPath = self.tableView.indexPath(for: cell)!
            if let name = self.dataRows[indexPath.row]["Name"] as? String {
                destination.name = name
            }
            if let contactId = self.dataRows[indexPath.row]["Id"] as? String {
                destination.contactId = contactId
            }
        }
    }
}
