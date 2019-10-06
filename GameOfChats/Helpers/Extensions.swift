//
//  Extensions.swift
//  GameOfChats
//
//  Created by Александр Кондрашин on 12/07/2019.
//  Copyright © 2019 Alexander Kondrashin. All rights reserved.
//

import UIKit

let imageCache = NSCache<NSString, AnyObject>()


extension UIImageView {
    
    func loadImageUsingCacheWithUrlString(urlString: String) {
        
        self.image = nil
        
        if let cacheImage = imageCache.object(forKey: urlString as NSString) as? UIImage {
            self.image = cacheImage
            return
        }
        
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!) { (data, response, error) in
            if error != nil {
                print(error)
            } else {
                DispatchQueue.main.async {
                    if let downloadedImage = UIImage(data: data!) {
                        imageCache.setObject(downloadedImage, forKey: urlString as NSString)
                        self.image = downloadedImage
                    }
                }
            }
            }.resume()
    }
}
