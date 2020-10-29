//*
// * Copyright (C) Schweizerische Bundesbahnen SBB, 2020.
//*
//

import Foundation
import CoreData


extension PhotoData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PhotoData> {
        return NSFetchRequest<PhotoData>(entityName: "PhotoData")
    }

    @NSManaged public var image: Data?
    @NSManaged public var pin: Pin?

}

extension PhotoData : Identifiable {

}
