//
//  Message.swift
//  GameOfChats
//
//  Created by Александр Кондрашин on 31/07/2019.
//  Copyright © 2019 Alexander Kondrashin. All rights reserved.
//

import UIKit
import FirebaseAuth

class Message: NSObject {

    var fromId : String?
    var text : String?
    var timestamp : NSNumber?
    var toId : String?
    
    var imageUrl : String?
    var videoUrl : String?
    
    var imageWidth : NSNumber?
    var imageHeight : NSNumber?
    
    func chatPartnerId() -> String? {
        return fromId == Auth.auth().currentUser?.uid ? toId : fromId
    }
    
    init(dictionary: [String : Any]) {
        fromId = dictionary["fromId"] as? String
        toId = dictionary["toId"] as? String
        text = dictionary["text"] as? String
        timestamp = dictionary["timestamp"] as? NSNumber
        imageUrl = dictionary["imageUrl"] as? String
        imageWidth = dictionary["imageWidth"] as? NSNumber
        imageHeight = dictionary["imageHeight"] as? NSNumber
        videoUrl = dictionary["videoUrl"] as? String
    }

}


