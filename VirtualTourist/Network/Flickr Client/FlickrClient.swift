//*
// * Copyright (C) Schweizerische Bundesbahnen SBB, 2020.
//*

import Foundation

class FlickrClient{
    struct Auth{
        static var apiKey = "0a0bbcd34f33b43f5a179190cc8e7d0d"
    }
    
    enum Endpoints{
        static let base = "https://www.flickr.com/services/rest/?"
        case geoLocation(Double, Double, Int)
        
        var stringValue: String{
            switch self{
            case .geoLocation(let lat, let lon, let page):
                return Endpoints.base + "?method=flickr.photos.search&api_key=" + Auth.apiKey + "&lat=\(lat)&lon=\(lon)&per_page=10&page=\(page)&format=json&nojsoncallback=1"
                
            }
        }
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func taskGETRequest<ResponseType: Codable>(url: URL, _: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionDataTask{
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                print(error)
                do {
                    let errorResponse = try decoder.decode(ErrorResponse.self, from: data) as Error
                    DispatchQueue.main.async {
                        completion(nil, errorResponse)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
        }
        task.resume()
        
        return task
    }
    
    
    
    class func getPhotosByLocation(lat: Double, lon: Double, completion: @escaping(FlickrSearch?, Error?)->Void){

        let rndPage = Int.random(in: 1..<10)
        taskGETRequest(url: Endpoints.geoLocation(lat, lon, rndPage).url, FlickrSearch.self){
            response, error in
            if let response = response{
                completion(response, nil)
            }
            else{
                completion(nil, error)
                print(error)
            }
        }
    }
}
