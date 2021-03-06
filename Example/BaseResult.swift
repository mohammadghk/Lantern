//
//  BaseResult.swift
//  Example
//
//  Created by 2019 Mohammad Ghasemi on 8/11/19.
//  Copyright © 2019 Mohammad Ghasemi. All rights reserved.
//

import Foundation


struct BaseResult: Codable {
    let page : Int
    let total : Int
    var json :Data? {
        return try? JSONEncoder().encode(self)
    }
    
    init?(json: Data) {
        
        if let newValue = try? JSONDecoder().decode(BaseResult.self, from: json) {
            self = newValue
        } else {
            return nil
        }
    }
}
