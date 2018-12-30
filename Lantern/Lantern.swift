//
//  Lantern.swift
//  Lantern
//
//  Created by Mohammad on 12/8/16.
//  Copyright © 2016 Mohammad Ghasemi. All rights reserved.
//
/// Usage:
// adopt LanternDelegate in UIViewController and implement onSuccess and onError delegates
// init an instance of Lantern and set its delegates to self and parameters
// use call to send GET and use post to send POST requests

import Foundation
import Alamofire
import ObjectMapper

public protocol LanternDelegate  : class {
    
    func onSuccess(result : Any?, requestId : String?)
    func onError(error : Any?, requestId : String?)
    func onTimeOut(error: String?, requestId: String?) // Optional
}

public extension LanternDelegate{
    func onTimeOut(error: String?, requestId: String?){
        
    }
}

///  - S: type of result object
public class Lantern<S: BaseMappable,E:BaseMappable> {
    weak var delegate : LanternDelegate?
    var handler : String!
    var requestId : String?
    var params : Dictionary<String, String>?
    private var error : MGError?
    
    private var headers: HTTPHeaders = Alamofire.SessionManager.defaultHTTPHeaders
    //            "Os_Version" : "\(systemVersion)"
    //    let appVersionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
    //    let appBuildString = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
    //    let systemVersion = UIDevice.current.systemVersion
    
    init(delegate: LanternDelegate,handler : String!,params : Dictionary<String,String>?, requestId : String?) {
        self.delegate = delegate
        self.handler = handler
        self.requestId = requestId
        self.params = params
    }
    
    func appendHeader(param: [String:String]){
        for (key,value) in param{
            headers[key] = value
        }
    }
    
    //MARK: - HTTP Post and Call
    
    func call() {
        
        self.handler = self.handler.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        Alamofire.request(self.handler,parameters : params, headers : headers).responseJSON { response in
            print("URL Called : \(String(describing: response.request))")
            if response.response != nil{
                
                let res = Mapper<S>().map(JSONObject: response.result.value)
                let err = Mapper<E>().map(JSONObject: response.result.value)
                switch response.response!.statusCode {
                case 200 ..< 300 :
                    self.delegate?.onSuccess(result: res, requestId: self.requestId)
                    break
                case 401:
                    //FIXME: - unauthorized
                    print("***Error*** : Unauthorized")
                    self.delegate?.onError(error: err, requestId: self.requestId)
                    break
                default:
                    self.delegate?.onError(error: err, requestId: self.requestId)
                    break
                }
            }else{
                self.delegate?.onTimeOut(error: "Connection Error", requestId: self.requestId)
            }
        }
    }
    
    /// Post without body
    func post(){
        
        Alamofire.request(self.handler, method: .post, parameters: params, encoding: JSONEncoding.default , headers: headers).responseJSON {
            response in
            switch response.result {
            case .success:
                let res = Mapper<S>().map(JSONObject: response.result.value)
                let err = Mapper<E>().map(JSONObject: response.result.value)
                switch response.response?.statusCode ?? 401{
                case 200 :
                    
                    self.delegate?.onSuccess(result: res, requestId: self.requestId)
                    break
                    
                default :
                    self.delegate?.onError(error: err, requestId: self.requestId)
                    break
                }
                
                break
            case .failure(let error):
                self.delegate?.onTimeOut(error: error.localizedDescription, requestId: self.requestId)
            }
        }
    }
    
    
    /// Post function with body - only one param is needed in case there is a prepared object
    /// convert that object to json string and use bodyString else if creating parameters
    /// in a Dictionary convert it to data and use bodyData
    /// - Parameters:
    ///   - bodyString: body in json format casted to string
    ///   - bodyData: body in Dictionary format casted to Data
    func post(bodyString: String?, bodyData: Data?){
        
        var request = URLRequest(url: URL(string: self.handler)!)
        request.httpMethod = HTTPMethod.post.rawValue
        request.allHTTPHeaderFields = headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body = bodyString {
            let data = (body.data(using: .utf8))! as Data
            request.httpBody = data
        }
        
        if let body = bodyData {
            request.httpBody = body
        }
        
        Alamofire.request(request).responseJSON {
            response in
            print("Post URL Called : \(response.request!)")
            let res = Mapper<S>().map(JSONObject: response.result.value)
            let err = Mapper<E>().map(JSONObject: response.result.value)
            switch response.response?.statusCode ?? 401 {
            case 200 ... 300 :
                self.delegate?.onSuccess(result: res, requestId: self.requestId)
                break
            default :
                self.delegate?.onError(error: err, requestId: self.requestId) //FIXME: - Unathorized
                break
            }
        }
    }
}

class MGError{
    static let CONNECTION_ERROR : Int = 8009
    static let UNATHORIZED : Int = 8010
}


//MARK: - MultiPart Uploader

protocol UploadFormDataDelegate : class {
     func didUploadedSuccesful(result : Any? , requestId: String)
     func didUploadFailed(error: String? , requestId: String)
}

class UploadFormData<BaseResult:BaseMappable>{ //FIXME: Make it universal for images and pdf
    var delegate : UploadFormDataDelegate?
    var requestId = ""
    // import Alamofire
    func uploadWithAlamofire(file : Any , parameters : [String:String]?,destinationUrl: String,requestId: String?) {
        
        //        let imageName = "file"//imageName
        //        let fileName = "file.jpg"//fileName
        
        if let reqId = requestId {
            self.requestId = reqId
        }
        
        //        if imageName == nil {
        //            imageName = "file"
        //        }
        //        if fileName == nil {
        //            fileName = "file.png"
        //        }
        
        let headers: HTTPHeaders = [:]
        
        Alamofire.upload(multipartFormData: { multipartFormData in
            
            if parameters != nil {
                for (key, value) in parameters! {
                    multipartFormData.append((value).data(using: .utf8)!, withName: key)
                }
            }
            
            //            if let imageData = UIImageJPEGRepresentation(Image, 0.7) {
            //                multipartFormData.append(imageData, withName: imageName, fileName: fileName, mimeType: "image/jpeg")
            //            }
            
            //            multipartFormData.append(pdfData, withName: "pdfDocuments", fileName: namePDF, mimeType:"application/pdf")
            
        }, to: destinationUrl, method: .post, headers: headers,
           encodingCompletion: { encodingResult in
            switch encodingResult {
            case .success(let upload, _, _):
                upload.responseJSON { response in
                    
                    let res = Mapper<BaseResult>().map(JSONObject: response.result.value)
                    
                    switch response.result {
                    case .success:
                        print("jsonResponse ==== ", response)
                        self.delegate?.didUploadedSuccesful(result: res ,requestId: self.requestId)
                    case .failure(let error):
                        print("error ==== ", error)
                        self.delegate?.didUploadFailed(error: "Upload failed, try again" , requestId: self.requestId)
                    }
                }
            case .failure(let encodingError):
                print("error:\(encodingError)")
            }
        })
    }
    
}

