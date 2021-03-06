//*
// * Copyright (C) Schweizerische Bundesbahnen SBB, 2020.
//*

import Foundation
struct FlickrSearch: Codable {
    let photos: Photos
    let stat: String
    
    enum CodingKeys: String, CodingKey{
        case photos = "photos"
        case stat
    }
}

