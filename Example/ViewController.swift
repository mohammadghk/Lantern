//
//  ViewController.swift
//  Example
//x
//  Created by 2019 Mohammad Ghasemi on 8/11/19.
//  Copyright © 2019 Mohammad Ghasemi. All rights reserved.
//

import UIKit
import Lantern

class ViewController: UIViewController {
    
    @IBOutlet weak var logTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    @IBAction func clearLog(_ sender: Any) {
        logTextView.text = ""
    }
    @IBAction func maketheCall(_ sender: Any) {
        let requestHandler = Lantern<BaseResult>(url: "https://reqres.in/api/users", method: .get, params: ["page":"1"])
        requestHandler.emit { (result, response, error) in
            var log = ""
            if let res = result {
                log = "Result: \(res) \n"
                print(res)
            }
            if let err = error{
                log += "Error: \(err) \n"
                print(err)
            }
            if let resp = response {
                log += "HTTP Response: \(resp) \n"
                print(resp)
            }
            DispatchQueue.main.async {
            self.logTextView.text = log
            }
            
        }
    }
    
}

