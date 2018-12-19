//
//  ToDoTableViewController.swift
//  ToDoList2
//
//  Created by Jun Dang on 2018-12-18.
//  Copyright © 2018 Jun Dang. All rights reserved.
//

import UIKit
import CoreData

class ToDoTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let tableView: UITableView = UITableView(frame: CGRect.zero)
    let cell = "cell"
    var items = [Items]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var searchBar:UISearchBar?
    var searchBarActive:Bool = false
    var searchBarBoundsY:CGFloat?
    var isObserverAdded = false
    var toDOForSearchResult:[Items] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigationbar()
        loadItems()
               // Do any additional setup after loading the view.
    }
    
    func setupTableView() {
        tableView.frame = self.view.frame
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cell)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.tableFooterView = UIView()
        //tableView.isEditing = true
        prepareSearchBar()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.searchBarActive {
            return toDOForSearchResult.count
        }
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: self.cell, for: indexPath as IndexPath)
        let item = (self.searchBarActive) ? toDOForSearchResult[indexPath.row] : items[indexPath.row]
        cell.textLabel?.text = item.name
        cell.accessoryType = item.completed ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("select row")
       
        tableView.deselectRow(at: indexPath, animated: true)
        items[indexPath.row].completed = !items[indexPath.row].completed
         print("completed: \(items[indexPath.row].completed)")
        saveItemsAndReloadTableView()
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if (editingStyle == .delete) {
            let item = items[indexPath.row]
            items.remove(at: indexPath.row)
            context.delete(item)
            
            saveItems()
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    /*func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }*/
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedItem = self.items[sourceIndexPath.row]
        items.remove(at: sourceIndexPath.row)
        items.insert(movedItem, at: destinationIndexPath.row)
    }
    
    func saveItems() {
        do {
            try context.save()
        } catch {
            print("Error saving item with \(error)")
        }
    }
    
    func loadItems() {
        
        let request: NSFetchRequest<Items> = Items.fetchRequest()
        
        do {
            items = try context.fetch(request)
        } catch {
             print("Error saving item with \(error)")
        }
        tableView.reloadData()
    }
    
}

extension ToDoTableViewController: UINavigationControllerDelegate, UINavigationBarDelegate {
    
    func setupNavigationbar() {
        navigationItem.title = "ToDoList"
        let addButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action:#selector(addTapped))
        navigationItem.rightBarButtonItem = addButton
       
        }
    @objc func addTapped(_sender: UIBarButtonItem) {
        var textField = UITextField()
        let alert = UIAlertController(title: "Add New Item", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "Add Item", style: .default) { (action) in
            let newItem = Items(context: self.context)
            newItem.name = textField.text!
            self.items.append(newItem)
            self.saveItemsAndReloadTableView()
        }
        
        alert.addAction(action)
        
        alert.addTextField { (field) in
            
            textField = field
            textField.placeholder = "Add a New Item"
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    func saveItemsAndReloadTableView() {
        
       saveItems()
       tableView.reloadData()
    }
 }

extension ToDoTableViewController: UISearchBarDelegate {
    func prepareSearchBar(){
        self.addSearchBar()
    }
    
    func addSearchBar(){
        if self.searchBar == nil {
            self.searchBarBoundsY = (self.navigationController?.navigationBar.frame.size.height)! + UIApplication.shared.statusBarFrame.size.height
            self.searchBar = UISearchBar(frame: CGRect(x: 0,y: self.searchBarBoundsY!, width: UIScreen.main.bounds.size.width, height: 44))
            self.searchBar!.searchBarStyle       = UISearchBar.Style.minimal
            self.searchBar!.tintColor            = UIColor(red: (0/255.0), green: (153/255.0), blue: (0/255.0), alpha: 1.0)
            self.searchBar!.barTintColor         = UIColor.white
            self.searchBar!.delegate             = self
            self.searchBar!.placeholder          = "Search"
            self.searchBar!.setShowsCancelButton(false, animated: true)
            let textFieldInsideUISearchBar = searchBar!.value(forKey: "searchField") as? UITextField
            textFieldInsideUISearchBar?.font = UIFont(name: "HelveticaNeue", size: 15)
            tableView.tableHeaderView = searchBar
            tableView.tableHeaderView?.backgroundColor = UIColor(red: (224/255.0), green: (224/255.0), blue: (224/255.0), alpha: 1.0)
        }
        if !self.searchBar!.isDescendant(of: self.view){
            self.view.addSubview(self.searchBar!)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.cancelSearching()
        self.tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBarActive = true
        self.view.endEditing(true)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar!.setShowsCancelButton(true, animated: true)
        let uiButton = searchBar.value(forKey: "cancelButton") as! UIButton
        uiButton.setTitle("cancel", for: UIControl.State())
        uiButton.setTitleColor(UIColor(red: (0/255.0), green: (153/255.0), blue: (0/255.0), alpha: 1.0), for: UIControl.State())
        uiButton.titleLabel!.font = UIFont(name: "HelveticaNeue", size: 15)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.searchBarActive = false
        self.searchBar!.setShowsCancelButton(false, animated: false)
        self.searchBar!.resignFirstResponder()
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
       
        self.toDOForSearchResult = items.filter({( item : Items) -> Bool in
            if let itemName = item.name {
                print(itemName.lowercased().contains(searchText.lowercased()))
                return itemName.lowercased().contains(searchText.lowercased())
            } else {
                return false
            }
            
        })
        print("result: \(self.toDOForSearchResult[0].name)")
    
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count > 0 {
            self.searchBarActive    = true
            self.filterContentForSearchText(searchText)
            tableView.reloadData()
        } else {
            self.searchBarActive = false
            tableView.reloadData()
        }
    }
    
    func cancelSearching(){
        self.searchBarActive = false
        self.searchBar!.resignFirstResponder()
        self.searchBar!.text = ""
    }
    
    func addObservers(){
        isObserverAdded = true
        let context = UnsafeMutablePointer<UInt8>(bitPattern: 1)
        self.tableView.addObserver(self, forKeyPath: "contentOffset", options: [.new,.old], context: context)
    }
    
    func removeObservers(){
        if (isObserverAdded) {
            self.tableView.removeObserver(self, forKeyPath: "contentOffset")
            isObserverAdded = false
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?){
        if keyPath! == "contentOffset" {
            if let tableV:UITableView = object as? UITableView {
                self.searchBar?.frame = CGRect(
                    x: self.searchBar!.frame.origin.x,
                    y: self.searchBarBoundsY! + ( (-1 * tableV.contentOffset.y) - self.searchBarBoundsY!),
                    width: self.searchBar!.frame.size.width,
                    height: self.searchBar!.frame.size.height
                )
            }
        }
    }
}



