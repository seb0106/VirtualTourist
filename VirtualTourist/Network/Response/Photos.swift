//*
// * Copyright (C) Schweizerische Bundesbahnen SBB, 2020.
//*

import Foundation
struct Photos: Codable{
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [Photo]
}
