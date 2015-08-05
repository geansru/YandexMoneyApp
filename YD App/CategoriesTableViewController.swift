//
//  CategoriesTableViewController.swift
//  YD App
//
//  Created by Dmitriy Roytman on 04.08.15.
//  Copyright (c) 2015 Dmitriy Roytman. All rights reserved.
//

import UIKit
import CoreData

class CategoriesTableViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    // MARK: Variables
    var categories: [PaymentCategory]!
    var searches: [PaymentCategory]!
    var save: [PaymentCategory]!
    var isSearch = false
    var managedContext: NSManagedObjectContext!
    
    // MARK: Constants
    let ENTITY_NAME_CATEGORY: String = "PaymentCategory"
    let ENTITY_NAME_SUBCATEGORY: String = "PaymentSubCategory"

    // MARK: IBOutlet's
    @IBOutlet var field: UITextField!
    @IBOutlet var table: UITableView!
    @IBOutlet weak var clearButton: UIBarButtonItem!
    // MARK: IBAction's
    @IBAction func reloadAction(sender: AnyObject) {
        checkStorage()
    }
    
    @IBAction func dropAction(sender: AnyObject) {
        categories = save
        isSearch = false
        field.text = ""
        field.resignFirstResponder()
        table.becomeFirstResponder()
        tableView.reloadData()
        
    }
    
    // MARK: Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        field.delegate = self
        checkStorage()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return categories?.count ?? 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return categories?[section].subcategories.count ?? 0
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! UITableViewCell
        let set = categories[indexPath.section].subcategories
        let sub = set[indexPath.row] as! PaymentSubCategory
        
        cell.textLabel?.text = sub.title
        cell.detailTextLabel?.text = "id: \(sub.id)"
        cell.tag = indexPath.section
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return categories[section].title
    }
    
    // MARK: UITextFieldDelegate methods
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let oldString: NSString = textField.text
        let newString: NSString = oldString.stringByReplacingCharactersInRange(range, withString: string)
        if newString.length > 0 {
            isSearch = true
            search(newString.lowercaseString)
        } else {
            isSearch = false
        }
        clearButton.enabled = isSearch
        backup()
        return true
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        let controller: DetailsTableViewController = segue.destinationViewController as! DetailsTableViewController
        // Pass the selected object to the new view controller.
        let cell = sender as! UITableViewCell
        let index = cell.tag
        let strIndex: String.Index = advance(cell.detailTextLabel!.text!.startIndex, 3)
        let text: NSString = cell.detailTextLabel!.text!.substringFromIndex(strIndex)
        let j: Int = text.integerValue
        let id: NSNumber = NSNumber(integer: j)
        let subs = getSubs(index)
        var result = [PaymentSubCategory]()
        for var i = 0; i < subs.count; i++ {
            if subs[i].id == id {
                result.append(subs[i])
            }
        }
        controller.subs = result

    }
    
    // MARK: Helpers method
    
    private func search(text: String) {
        let re = NSRegularExpression(pattern: text, options: nil, error: nil)
        searches = [PaymentCategory]()
        for var i = 0; i < save.count; i++ {
            let e = save[i]
            if let match = re?.firstMatchInString(e.title.lowercaseString, options: nil, range: NSRange(location: 0, length: count(e.title))) {
                searches.append(e)
            } else {
                for sub in e.subcategories {
                    let subCategory = sub as! PaymentSubCategory
                    if let match = re?.firstMatchInString(subCategory.title.lowercaseString, options: nil, range: NSRange(location: 0, length: count(subCategory.title))) {
                        searches.append(e)
                    }
                }
            }
        }
        categories = searches
        tableView.reloadData()
    }
    
    private func backup() {
        if !isSearch {
            categories = save
        }
        tableView.reloadData()
    }
    
    private func getSubs(index: Int) -> [PaymentSubCategory]{
        let aux = categories[index].subcategories
        var result: [PaymentSubCategory] = [PaymentSubCategory]()
        for e in aux {
            result.append(e as! PaymentSubCategory)
        }
        return result
    }
    
    private func checkStorage() {
        let entity = NSEntityDescription.entityForName(ENTITY_NAME_CATEGORY, inManagedObjectContext: managedContext)

        let fetch = NSFetchRequest(entityName: ENTITY_NAME_CATEGORY)

        var error: NSError?
        let result = managedContext.executeFetchRequest(fetch, error: &error) as! [PaymentCategory]?
        if let categories = result {
            
            if categories.count == 0 {
                self.categories = [PaymentCategory]()
                download()
            } else {
                self.categories = categories
                self.save = categories
            }
        } else {
            println("Could not fetch: \(error)")
        }
        
    }
    
    private func drop() {
        categories = [PaymentCategory]()
        dropAll(ENTITY_NAME_SUBCATEGORY)
        dropAll(ENTITY_NAME_CATEGORY)
    }
    
    private func dropAll(name: String) {
        let entity = NSEntityDescription.entityForName(name, inManagedObjectContext: managedContext)
        let fetch = NSFetchRequest(entityName: name)
        var error: NSError?
        let result = managedContext.executeFetchRequest(fetch, error: &error) as! [NSManagedObject]?
        
        if result?.count > 0 {
            for object in result! {
                managedContext.deleteObject(object)
            }
            var error: NSError?
            if !managedContext.save(&error) {
                println(error)
            }
        }
    }
    
    private func download() {
        let path = "https://money.yandex.ru/api/categories-list"
        
        let url: NSURL = NSURL(string: path)!
        
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithURL(url) { data, task, error -> Void in
            if (error != nil) {
                println(error)
            } else {
                var error: NSError? = nil
                let jsonResult: NSArray = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &error) as! NSArray
                for e in jsonResult {
                    let categoryDict = e as! NSDictionary
                    self.append(categoryDict)
                }
                self.save = self.categories
                self.table.reloadData()
            }
        }
        task.resume()
    }

    private func append(d: NSDictionary) {
        let title: String = d["title"]! as! String
        let subs: [NSDictionary] = d["subs"]! as! [NSDictionary]
        let entity = NSEntityDescription.entityForName(ENTITY_NAME_CATEGORY, inManagedObjectContext: managedContext)
        let subsEntity = NSEntityDescription.entityForName(ENTITY_NAME_SUBCATEGORY, inManagedObjectContext: managedContext)
        let currentCat = PaymentCategory(entity: entity!, insertIntoManagedObjectContext: managedContext)
        currentCat.title = title
        self.categories.append(currentCat)
        tableView.reloadData()
        var subsEntities: [PaymentSubCategory] = [PaymentSubCategory]()
        
        for e: NSDictionary in subs {
            let ID = e["id"] as! Int
            let title = e["title"] as! String
            let sub = PaymentSubCategory(entity: subsEntity!, insertIntoManagedObjectContext: managedContext)
            sub.title = title
            sub.id = ID
            
            subsEntities.append(sub)
        }
        
        let set = NSOrderedSet(array: subsEntities)
        
        currentCat.subcategories = set
        
        var error: NSError?
        if !managedContext.save(&error) {
            println("Could not save: \(error)")
        }
    }
}
