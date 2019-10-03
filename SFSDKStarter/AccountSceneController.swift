//
//  AccountSceneController.swift
//  SFSDKStarter
//
//  Created by Kevin Poorman on 7/11/19.
//  Copyright © 2019 Salesforce. All rights reserved.
//

import Foundation
import UIKit
import SalesforceSDKCore

class AccountSceneController: UITableViewController {
    var dataRows = [Dictionary<String, Any>]()
    
    override func loadView() {
        super.loadView()
        self.title = "Accounts"
        let request = RestClient.shared.request(forQuery: "SELECT Id, Name FROM Account LIMIT 10")
        
        RestClient.shared.send(request: request, onFailure: { (error, urlResponse) in
            SalesforceLogger.d(type(of:self), message:"Error invoking: \(request)")
        }) { [weak self] (response, urlResponse) in
            
            guard let strongSelf = self,
                let jsonResponse = response as? Dictionary<String,Any>,
                let result = jsonResponse ["records"] as? [Dictionary<String,Any>] else {
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
        let cellIdentifier = "AccountNameCellIdentifier"
        
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
        if segue.identifier == "toContactsSceneController" {
            let destination = segue.destination as! ContactsSceneController
            let cell = sender as! UITableViewCell
            let indexPath = self.tableView.indexPath(for: cell)!
            if let accountName = self.dataRows[indexPath.row]["Name"] as? String {
                destination.name = accountName
            }
            if let accountId = self.dataRows[indexPath.row]["Id"] as? String {
                destination.accountId = accountId
            }
        }
    }
}
