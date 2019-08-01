# Getting a list of Accounts

## Overview

This step is jam packed with functionality. You'll query for data from Salesforce, handle the asynchronous result, and display the data in a table view. This step starts off with a concrete copy/paste step, but in the end you'll need to do this same kind of work a few more times.

## Using the SDK to query for information

The SDK has a number of built in methods that make it easy to create, read, update, destroy and query your Salesforce data. The SDK relies on standard REST API's to accomplish these tasks. This means anytime your Org automations (Triggers, Processes etc.) would normally kick in, apply here as well.

First things first. Before we can interact with Salesforce data we need to create a new scene controller and setup our storyboard. Create a new Swift file by:

1. Click `File > New > File` (or click `cmd-n`).
2. Make sure to choose Swift file.
3. Click Next.
4. Name your file AccountSceneController.
5. Ensure the target checkbox for 'SFSDKStarter' is checked.

By default, Xcode will open your new Swift file as soon as it's created. Add these two lines just below the default `import Foundation` statment at the top:

```swift
import UIKit
import SalesforceSDKCore

class AccountSceneController: UITableViewController {
  var dataRows = [Dictionary<String, Any>]()

}
```

The first thing we do in this class, is create an array of dictionaries. Why? This is going to hold our account rows we get back from Salesforce. Each account we get back will be a dictionary (in Apex we call these Maps) of key (field name), value pairs. We need an array of these dictionaries because we expect to get more than one account back.

> Now's a good time to save this file.

These lines give us access to UIKit, which we'll use for data display, and the Salesforce SDK. For now, save your file.

Open the Main.storyboard. By default, Xcode includes a tab-based navigation controller. You'll also notice a new 'Navigator' style pane.

![Storyboard Navigator](https://codefriar.github.io/IOSAndSalesforce/img/storyboardScenes.png "Storyboard Navigator")

Clicking on each of the scenes and hit your delete key to remove them. We want to start with a blank slate.

Once you've got a blank slate, click the library button and search for navigation. You should see this:

![Library](https://codefriar.github.io/IOSAndSalesforce/img/addNavigationController.png "add Navigation Controller")

Click on, and drag the navigation controller to your storyboard. Congrats, you've just started your User Interface. Adding a Navigation Controller gives you the ability to add additional scenes, and navigate between them. Looking carefully, you'll see that adding the Navigation Controller actually put two objects on the storyboard canvas. The first is the Navigation Controller itself, and the second, on the right, is the first scene. This is the initial scene that users will see when your app boots. By default that initial scene is a UITableView. We need to link the storyboard scene to the Swift class we just created.

This is pretty easy to do in Xcode, but it can be a bit confusing for new Xcode users because Xcode packs so much funcationality into it's user interface. Here's how to do it.

1. While you have the Main storyboard open, use the scene navigator, and select `Root View Controller`.
2. Using the right hand navigator, select the `Identity Inspector` - the icon looks like a little drivers license.
3. The top section is titled 'Custom Class' and has a 'class' drop down. Using that drop down, select AccountSceneController. Note, if you don't see your AccountSceneController listed, make sure you've saved your file and that you've coded your class to inherit from the `UITableViewController` class.

![Identity Inspector](https://codefriar.github.io/IOSAndSalesforce/img/changeAssociatedController.png "Change the assocaited controller class")

That'ts it. You just used Interface Builder to drag and drop a Navigation Controller into your app! Additionally, you tied your new scene to your custom class! Now, lets make it do something interesting!

## Walking through the class logic

For this step, we're providing you the class logic, but we're going to do it one block at a time so we can walk through it.

### LoadView()

```swift
// MARK: - View lifecycle
override func loadView() {
    super.loadView()
    self.title = "Accounts"
    let request = RestClient.shared.request(forQuery: "SELECT Id, Name FROM Account LIMIT 10")

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
```

`loadView()` is a lifecycle method. This means that whenever iOS loads a view, it's associated controller's lifecycle methods are automatically run in a prescribed order. If you'd like to know more about the View Controller lifecyle methods, [click here](https://medium.com/@amyjoscelyn/the-life-cycle-of-a-view-c98f296fd84e) For now, it's important to understand that `loadView()` acts as a kind of constructor, called immediately as the view loads.

It's in this `loadView()` method that the app will reach out to Salesforce for data. Specifically, it's going to query for 10 Accounts. In this case, it's accomplished in three distinct steps.

- Creating a request. `let request = RestClient.shared.request(forQuery: "SELECT Id, Name FROM Account LIMIT 10")`. The SDK has a number of helper methods for generating requests. Discovering what helpers are avaialble is as simple as letting Xcode autocomplete for you.

![XCode Autocomplete](https://codefriar.github.io/IOSAndSalesforce/img/requestAutocomplete.png "Shows Xcode autocomplete for request methods")

- Execute the request. Because we have no idea how strong the network signal is, we can never assume how quickly -- or if -- an API request will complete. To prevent API requests from locking up the app, all API requests are asynchronous. In Swift, that means using completion callbacks. In most cases these are closures, and with regards to the SDK, there's usually two: an error closure and a success or completion closure. Executing the request happens when you call `RestClient.shared.send(...` method.

- Finally, in our completion closure, we need to parse the data Salesforce returns and assign it to our dataRows variable. This block contains a `guard let` clause. This is a Swift specific language feature that helps developers write defensive code. When a guard statement is encounterd the let assignments are evaluated. If they're not valid, the else clause is executed. If they're valid, those let assignments are avaiable through the rest of the method. In this case, the code is cascading the let assignments. This is how we step-by-step unpack the returned data from Salesforce. At the very end, the code assigns the result to the dataRows variable.

Whew. That was dense. The rest is easier, I promise.

### UITableViewController methods

```swift
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
```

Because we specified that our AccountSceneController inherits from UITableViewController there are a number of methods we must implement. Two of them are pretty easy, and serve as a great example of how to read and write iOS method names. Lets take a look at the first one, `numberOfSectionsInTableView(tableView: UITableView) -> Int`. iOS methods may seem verbose, bu they're very descriptive. In this case, the method name is self-descriptive. It should return an Int, representing the number of sections in the table view. What's a section? Think of your iOS contacts view. As you scroll through, you'll see a section for each letter of the alphabet. For this app, none of our table views will have more than one section; which makes implementing it pretty simple.

Likewise, the `tableView(_ tableView: UITableView?, numberOfRowsInSection section: Int) -> Int` method's name tells us exactly what it's supposed to do. For a given table view, how many rows are in this section? Because we only have one section, we can shortcut our implmentation and always respond with the length of our dataRows array.

Finally, we come the core method: `override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {...}`. This method is responsible for drawing each individual cell in the table. There are a number of options here, but the two key bits are:

1. ```swift
   let obj = dataRows[indexPath.row]
   cell.textLabel?.text = obj["Name"] as? String
   ```
   That indexPath.row thats passed in by iOS tells us what row in the table iOS is working on at the moment. Using that, coupled with our dataRows array, we can set the cell's text label to the Name of our account.
2. Since we know that we want the user to be able to tap on an account to navigate to a table of it's contacts, let's add the conventional > disclosure triangle with this:
   ```swift
   cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
   ```

Ok, home stretch. only one method left. This is one we've mentioned before and it's used to pass data between veiw controllers as users trigger a segue. There are two key features of this method I want to draw your attention too.

1. Right at the beginning the code checks to see if the segue we're triggering has an identifier of "ViewContacts". This string of "ViewContacts" has to match the segue in Interface builder. To create a new segue between two ViewControllers Control-click on the Scene handle, and drag to the destination ViewController. You'll see a pop up to select the type of segue. For this app, always choose 'Show'
   ![Creating a new Segue](https://codefriar.github.io/IOSAndSalesforce/img/newSegue.png "Shows how to create a new segue")
2. Once you'ce created the segue between view controllers, you'll need to give it a viewIdentifier. To do so, click on the segue itself, and use the right-hand navigator to show the Attributes inspector. Make sure the segue identifier is unique!
   ![Giving the Segue an Identifier](https://codefriar.github.io/IOSAndSalesforce/img/nameSegueIdentifier.png "Shows how to give a segue a unique identifier")

```swift
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
```

Notice how it creates an instance of the destination object named destination? At the end of the method it assigns data to the instances' properties. This is how you pass data from one viewController to the next.

## Run it!

Ok, it's time to compile and run our app on the simulator. Either click the play button in upper left, or hit `cmd-r` to build and run your app!

## Next Steps

Our app is designed to first show a list of accounts. Which we've done. Now it's up to you to handle the other two steps - showing a list of contacts associated with this account, and when a contact is tapped, showing their contact information. Here's a blueprint for the tasks in this step:

1. Create two new Swift files named 'ContactsSceneController' and 'ContactDetailSceneController'
2. Add two new TableViewControllers to your Storyboard Canvas.
3. Give one the identifier 'toContactsSceneController' and other the identifier 'toContactDetailController'
4. Code your Controllers to:
   - query for the appropriate data. Remember you'll be passing id's from one viewController to another as the user taps a particluar row.
   - create the cells as needed
   - set up data passing from one view controller to the next

<a href="step5.html" class="btn btn-default pull-right">Next <i class="glyphicon glyphicon-chevron-right"></i></a>
