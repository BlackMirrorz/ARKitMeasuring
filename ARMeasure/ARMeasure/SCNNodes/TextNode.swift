//
//  TextNode.swift
//  Setup
//
//  Created by Josh Robbins on 24/02/2018.
//  Copyright © 2018 BlackMirror. All rights reserved.
//

import Foundation
import SceneKit
import UIKit

class TextNode: SCNNode{

    enum PivotAlignment{
        
        case Left
        case Right
        case Center
    }
    
    var textGeometry: SCNText!
    
    /// Creates An SCNText Geometry
    ///
    /// - Parameters:
    ///   - text: String (The Text To Be Displayed)
    ///   - depth: Optional CGFloat (Defaults To 1)
    ///   - font: UIFont
    ///   - textSize: Optional CGFloat (Defaults To 3)
    ///   - colour: UIColor
    init(text: String, depth: CGFloat = 1, font: String = "Helvatica", textSize: CGFloat = 0.1, colour: UIColor) {
        
        super.init()
        
        //1. Create A Billboard Constraint So Our Text Always Faces The Camera
        let constraints = SCNBillboardConstraint()
        
        //2. Create An SCNNode To Hold Out Text
        let node = SCNNode()
        let max, min: SCNVector3
        let tx, ty, tz: Float
        
        //3. Set Our Free Axes
        constraints.freeAxes = .Y
        
        //4. Create Our Text Geometry
        textGeometry = SCNText(string: text, extrusionDepth: depth)
        
        //5. Set The Flatness To Zero (This Makes The Text Look Smoother)
        textGeometry.flatness = 0
        
        //6. Set The Alignment Mode Of The Text
        textGeometry.alignmentMode = kCAAlignmentCenter
        
        //7. Set Our Text Colour & Apply The Font
        textGeometry.firstMaterial?.diffuse.contents = colour
        textGeometry.firstMaterial?.isDoubleSided = true
        textGeometry.font = UIFont(name: font, size: textSize)
       
        //8. Position & Scale Our Node
        max = textGeometry.boundingBox.max
        min = textGeometry.boundingBox.min
        
        tx = (max.x - min.x) / 2.0
        ty = min.y
        tz = Float(depth) / 2.0
        
        node.geometry = textGeometry
        node.scale = SCNVector3(0.001, 0.001, 0.001)
        node.pivot = SCNMatrix4MakeTranslation(tx, ty, tz)
        
        self.addChildNode(node)
        
        self.constraints = [constraints]
    
    }
    
    
    /// Places The TextNode Between Two SCNNodes
    ///
    /// - Parameters:
    ///   - nodeA: SCNode
    ///   - nodeB: SCNode
    func placeBetweenNodes(_ nodeA: SCNNode, and nodeB: SCNNode){
        
        let minPosition = nodeA.position
        let maxPosition = nodeB.position
        let x = ((maxPosition.x + minPosition.x)/2.0)
        let y = (maxPosition.y + minPosition.y)/2.0 + 0.01
        let z = (maxPosition.z + minPosition.z)/2.0
        self.position =  SCNVector3(x, y, z)
    }
    
    //-----------------------
    //MARK: Pivot Positioning
    //-----------------------
    
    /// Sets The Pivot Of The TextNode
    ///
    /// - Parameter alignment: PivotAlignment
    func setTextAlignment(_ alignment: PivotAlignment){
        
        //1. Get The Bounding Box Of The TextNode
        let min = self.boundingBox.min
        let max = self.boundingBox.max
        
        switch alignment {
            
        case .Left:
            self.pivot = SCNMatrix4MakeTranslation(
                min.x,
                min.y + (max.y - min.y)/2,
                min.z + (max.z - min.z)/2
            )
        case .Right:
            self.pivot = SCNMatrix4MakeTranslation(
                max.x,
                min.y + (max.y - min.y)/2,
                min.z + (max.z - min.z)/2
            )
        case .Center:
            self.pivot = SCNMatrix4MakeTranslation(
                min.x + (max.x - min.x)/2,
                min.y + (max.y - min.y)/2,
                min.z + (max.z - min.z)/2
            )
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
}
