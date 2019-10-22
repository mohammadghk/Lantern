//
//  Lantern.swift
//  Lantern
//
//  Created by Mohammad on 12/8/16.
//  Copyright © 2016 Mohammad Ghasemi. All rights reserved.
//


import Foundation
import Alamofire


open class Lantern<S: Codable> {
    var url : String!
    var params : [String:String]?
    var method : HTTPMethod = .get
    var hasBodyData = false
    
    private var headers: [String:String] = Alamofire.SessionManager.defaultHTTPHeaders
//        ["Content-Type": "application/json","accept": "application/json"]
    
    public init(url : String!,method: HTTPMethod,params : [String:String]?, hasBodyData:Bool = false) {
        self.url = url
        self.method = method
        self.params = params
        self.hasBodyData = hasBodyData
    }
    
    public func appendHeader(param: [String:String]){
        for (key,value) in param{
            headers[key] = value
        }
    }
    
    //MARK: - HTTP Request
    
    public func emit(completion: @escaping (S?, HTTPURLResponse?, String?) -> ()) {
        let encoding: ParameterEncoding = self.hasBodyData ? JSONEncoding.default : URLEncoding.default
        print("""
            Request Called: \(url ?? "") |
            Headers: \(headers) |
            Method: \(method.rawValue) |
            Params: \(String(describing: params)) |
            """)
        //TODO: Handle stand-alone authentication
        Alamofire.request(self.url, method: method, parameters: params, encoding: encoding , headers: headers)
//            .authenticate(user: UserManager.shared.getPhone(), password: UserManager.shared.getToken())
            .responseJSON {
                response in
                
                //TODO: Handle global Loading
                print("Status Code: \(response.response?.statusCode ?? 0)")
                switch response.result {
                case .success:
                    switch response.response?.statusCode ?? 600{
                    case 200 :
                        if let data = response.data{
                            do{
                                let res = try JSONDecoder().decode(S.self, from: data)
                                completion(res,response.response,nil)
                            }catch let error{
                                print(error)
                                completion(nil,response.response,nil)
                            }
                            
                        }
                        break
                    case 401 :
                        //Unauthorized
                        completion(nil,response.response ,nil)
                    default :
                        print("Status Code : \(String(describing: response.response?.statusCode))")
                        completion(nil,response.response ,nil)
                        break
                    }
                    
                    break
                case .failure: // Time out
                    if let errData = response.data{
                        let msg = String(data: errData, encoding: .utf8) ?? "Could not connect to server"
                        completion(nil,response.response ,msg)
                    }else{
                        completion(nil,response.response ,nil)
                    }
                }
        }
    }
}




class UploadFormData<S:Codable>{ //FIXME: Make it universal for images and pdf
    
    
    
    // import Alamofire
    class func uploadWithAlamofire(file : UIImage ,headers: [String:String], parameters : [String:String]?,destinationUrl: String,completion: @escaping (S?, HTTPURLResponse?, String?) -> ()) {
        
        var baseHeaders: [String:String] = ["Content-Type": "application/json","accept": "application/json"]
        let imageName = "image"//imageName
        let fileName = "image.jpg"//fileName
        
        
        for (key,value) in headers{
            baseHeaders[key] = value
        }
//        let username = UserManager.shared.getPhone()
//        let password = UserManager.shared.getToken()
//
//        let credentialData = "\(username):\(password)".data(using: .utf8)
//        let base64Credentials = credentialData!.base64EncodedData()
//        baseHeaders["Authorization"] = "\(base64Credentials)"
        
        Alamofire.upload(multipartFormData: { multipartFormData in
            
            if parameters != nil { // body data
                for (key, value) in parameters! {
                    multipartFormData.append((value).data(using: .utf8)!, withName: key)
                }
            }
            
            if let imageData = file.jpegData(compressionQuality: 1) {
                multipartFormData.append(imageData, withName: imageName, fileName: fileName, mimeType: "image/jpeg")
            }else{
                //                            multipartFormData.append(pdfData, withName: "pdfDocuments", fileName: namePDF, mimeType:"application/pdf")
                //
            }
            
        }, to: destinationUrl, method: .post, headers: headers,
           encodingCompletion: { encodingResult in
            switch encodingResult {
            case .success(let upload, _, _):
                upload.responseJSON { response in
                    
                    
                    switch response.result {
                    case .success:
                        print("jsonResponse ==== ", response)
                        if let data = response.data {
                            var res : S?
                            do {
                                res = try JSONDecoder().decode(S.self, from: data)
                            }catch{
                                res = nil
                            }
                            completion(res, response.response, nil)
                        }
                        
                    case .failure(let error):
                        print("error ==== ", error)
                        if let errData = response.data{
                            let msg = String(data: errData, encoding: .utf8) ?? "Could not connect to server"
                            completion(nil,response.response ,msg)
                        }else{
                            completion(nil,response.response ,nil)
                        }
                    }
                }
            case .failure(let encodingError):
                print("error:\(encodingError)")
            }
        })
    }
    
}

