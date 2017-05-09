//
//  Route+CoreDataProperties.swift
//  PaceSetter
//
//  Created by JessicaChen on 4/11/16.
//  Copyright © 2016 JessicaChen. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Route {

    @NSManaged var date: Date
    @NSManaged var distance: Double
    @NSManaged var duration: TimeInterval
    @NSManaged var speed: Double
    @NSManaged var locations: NSOrderedSet?

}
