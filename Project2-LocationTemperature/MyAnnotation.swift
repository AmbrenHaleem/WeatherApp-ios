//
//  MyAnnotation.swift
//  Project2-LocationTemperature
//
//  Created by Ambreen Zahid on 2023-03-27.
//

import Foundation
import MapKit

class MyAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var glyphText: String?
    var code: Int?
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, glyphText: String? = nil, code: Int) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.glyphText = glyphText
        self.code = code
        
        super.init()
    }
}
