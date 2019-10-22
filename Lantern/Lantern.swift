//
//  Lantern.swift
//  Lantern
//
//  Created by Mohammad on 12/8/16.
//  Copyright © 2016 Mohammad Ghasemi. All rights reserved.
//

import Foundation


open class Lantern<S: Codable> {

    var url : String!
    var requestId : String?
    var params : [String:String]?
    var method : String = "GET"
    var bodyData: Data?
    var request : URLRequest!
    
    var headers: [String:String] = [:]//Alamofire.SessionManager.defaultHTTPHeaders
    
    public init(url : String!,method: HTTPMethod,params : [String:String]? = nil,bodyData:Data? = nil) {
        self.url = url
        self.method = method.rawValue
        self.params = params
        self.bodyData = bodyData
    }
    
    public func appendHeader(param: [String:String]){
        for (key,value) in param{
            headers[key] = value
        }
    }
    
    public func setAuthorizationHeader(username: String, password: String){
        guard let data = "\(username):\(password)".data(using: .utf8) else { return }
        
        let base64 = data.base64EncodedString()
        request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")
    }
    
    private func setParams(parameters: [String:String]?){
        if let params = parameters{
            var components = URLComponents(string: url)!
            components.queryItems = params.map { (key,value) in
                URLQueryItem(name: key, value: value)
            }
            components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
            self.request = URLRequest(url: components.url!)
        }else{
            self.request = URLRequest(url: URL(string: self.url)!)
        }
    }
    
    private func setDefaultHeaders(){
        self.request.allHTTPHeaderFields = self.headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
    }
    
    //MARK: - HTTP Post and Call
    
    public func emit(completion: @escaping (S?, HTTPURLResponse?, Error?) -> ()){
        setParams(parameters: params)
        setDefaultHeaders()
        
        self.request.httpMethod = self.method
        
        var session = URLSession.shared
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 45
        configuration.timeoutIntervalForResource = 45
        session = URLSession(configuration: configuration)
        
        
        if let body = bodyData {
            request.httpBody = body
        }
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            
            let res = try? JSONDecoder().decode(S.self, from: data!)
            
            if error != nil || data == nil {
                print("Client error!")
                return
            }
            
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                print("Oops!! there is server error!")
                completion(res, nil , error)
                return
            }
            
            guard let mime = response.mimeType, mime == "application/json" else {
                print("response is not json")
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: [])
                print("The Response is : ",json)
                completion(res, response , error)
            } catch {
                print("JSON error: \(error.localizedDescription)")
                completion(res, response , error)
            }
            
        })
        
        task.resume()
    }
}


public enum HTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}

