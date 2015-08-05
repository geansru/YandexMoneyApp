//
//  PaymentCategory.swift
//  YD App
//
//  Created by Dmitriy Roytman on 04.08.15.
//  Copyright (c) 2015 Dmitriy Roytman. All rights reserved.
//

import Foundation
import CoreData

class PaymentCategory: NSManagedObject {

    @NSManaged var title: String
    @NSManaged var subcategories: NSOrderedSet

}
