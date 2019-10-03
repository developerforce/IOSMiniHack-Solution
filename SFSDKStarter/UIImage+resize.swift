//
//  UIImage+resize.swift
//  SFSDKStarter
//
//  Created by Kevin Poorman on 9/25/19.
//  Copyright © 2019 Salesforce. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

extension UIImage {
    func resized(toPercentage percentage: CGFloat) -> UIImage {
        let canvas = CGSize(width: size.width * percentage, height: size.height * percentage)
        return UIGraphicsImageRenderer(size: canvas, format: imageRendererFormat).image {
            _ in draw(in: CGRect(origin: .zero, size: canvas))
        }
    }
    
    func resized(toWidth width: CGFloat) -> UIImage {
        let canvas = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        return UIGraphicsImageRenderer(size: canvas, format: imageRendererFormat).image {
            _ in draw(in: CGRect(origin: .zero, size: canvas))
        }
    }
}
