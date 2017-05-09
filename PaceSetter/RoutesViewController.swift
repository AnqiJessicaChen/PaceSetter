//
//  RoutesViewController.swift
//  PaceSetter
//
//  Created by JessicaChen on 4/11/16.
//  Copyright © 2016 JessicaChen. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

class RoutesViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var managedObjectContext: NSManagedObjectContext!
    lazy var fetchedResultsController: NSFetchedResultsController<Route> = {
        let fetchRequest = NSFetchRequest<Route>()
        let routeEntity = NSEntityDescription.entity(forEntityName: "Route", in: self.managedObjectContext)
        fetchRequest.entity = routeEntity
        
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchRequest.fetchBatchSize = 20
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: "Routes")
        
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        performFetch()
        navigationItem.rightBarButtonItem = editButtonItem
    }
    
    func performFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Error: \(error)")
        }
    }
    
    deinit {
        fetchedResultsController.delegate = nil
    }
    
    func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowRouteDetails" {
            let controller = segue.destination as! RouteDetailsViewController
            controller.managedObjectContext = managedObjectContext
            
            if let indexPath = tableView.indexPath(for: sender as! UITableViewCell) {
                let route = fetchedResultsController.object(at: indexPath) as! Route
                controller.routeToDisplay = route
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RouteCell", for: indexPath as IndexPath) as! RouteCell
        
        let route = fetchedResultsController.object(at: indexPath as IndexPath) as! Route
        cell.configureForRoute(route)
        return cell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .delete {
            let route = fetchedResultsController.object(at: indexPath as IndexPath) as! Route
            managedObjectContext.delete(route)
            
            do {
                try managedObjectContext.save()
            } catch {
                fatalError("Error: \(error)")
            }
        }
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .insert:
            //print("*** NSFetchedResultsChangeInsert (object)")
            tableView.insertRows(at: [newIndexPath! as IndexPath], with: .fade)
            
        case .delete:
            //print("*** NSFetchedResultsChangeDelete (object)")
            tableView.deleteRows(at: [indexPath! as IndexPath], with: .fade)
            
        case .update:
            //print("*** NSFetchedResultsChangeUpdate (object)")
            if let cell = tableView.cellForRow(at: indexPath! as IndexPath) as? RouteCell {
                let route = controller.object(at: indexPath! as IndexPath) as! Route
                cell.configureForRoute(route)
            }
            
        case .move:
            //print("*** NSFetchedResultsChangeMove (object)")
            tableView.deleteRows(at: [indexPath! as IndexPath], with: .fade)
            tableView.insertRows(at: [newIndexPath! as IndexPath], with: .fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //print("*** controllerDidChangeContent")
        tableView.endUpdates()
    }
    
}
