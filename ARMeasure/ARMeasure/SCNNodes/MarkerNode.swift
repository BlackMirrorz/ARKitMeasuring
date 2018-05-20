//
//  MarkerNode.swift
//  ARMeasure
//
//  Created by Josh Robbins on 19/05/2018.
//  Copyright © 2018 BlackMirrorz. All rights reserved.
//

import UIKit
import ARKit

class MarkerNode: SCNNode {

    /// Creates A Spherical Marker Node From A matrix_float4x4
    ///
    /// - Parameter matrix: matrix_float4x4
    init(fromMatrix matrix: matrix_float4x4 ) {
        
        super.init()
        
        //1. Convert The 3rd Column Values To Float
        let x = matrix.columns.3.x
        let y = matrix.columns.3.y
        let z = matrix.columns.3.z
        
        //2. Create A Marker Node At The Detected Matrixes Position
        let markerNodeGeometry = SCNSphere(radius: 0.005)
        markerNodeGeometry.firstMaterial?.diffuse.contents = UIColor.cyan
        self.geometry = markerNodeGeometry
        self.position = SCNVector3(x, y, z)
        
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("Coder Not Implemented") }

}
