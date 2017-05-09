//
//  Location+CoreDataProperties.swift
//  PaceSetter
//
//  Created by JessicaChen on 4/20/16.
//  Copyright © 2016 JessicaChen. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Location {

    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var elapsedTime: TimeInterval
    @NSManaged var route: Route?

}
