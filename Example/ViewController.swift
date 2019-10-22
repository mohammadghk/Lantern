//
//  ViewController.swift
//  Example
//
//  Created by Mohammad on 10/22/19.
//  Copyright © 2019 Mohammad Ghasemi. All rights reserved.
//

import UIKit
import Lantern

class ViewController: UIViewController {
    
    @IBOutlet weak var logTextView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    func testHandler() -> Lantern<BaseResult>{
        return Lantern<BaseResult>(url: "https://reqres.in/api/users", method: .get, params: ["page":"1"])
    }
    
    @IBAction func clearLog(_ sender: Any) {
        logTextView.text = ""
    }
    @IBAction func maketheCall(_ sender: Any) {
        testHandler().emit { (result, response, error) in
            if let res = result {
                self.logTextView.text = "Result: \(res) + \n"
                print(res)
            }
            if let err = error{
                self.logTextView.text += "Error: \(err) + \n"
                print(err)
            }
            if let resp = response {
                self.logTextView.text += "HTTP Response: \(resp) + \n"
                print(resp)
            }
        }
    }
    
}


