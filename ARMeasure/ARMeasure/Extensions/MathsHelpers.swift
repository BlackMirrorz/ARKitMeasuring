//
//  MathsHelpers.swift
//  ARMeasure
//
//  Created by Josh Robbins on 19/05/2018.
//  Copyright © 2018 BlackMirrorz. All rights reserved.
//

import Foundation
import ARKit

extension ViewController{
    
    /// Converts Metres To CM, MM, Feet & Inches
    ///
    /// - Parameter metres: Float
    /// - Returns: [String]
    func convertedLengthsFromMetres(_ metres: Float) -> ([Measurement<UnitLength>]){
        
        var measurements = [Measurement<UnitLength>]()
        
        //1. Convert The Length To The Units Needed
        let m = Measurement(value: Double(metres), unit: UnitLength.meters)
        let cm = m.converted(to: UnitLength.centimeters)
        let mm = m.converted(to: UnitLength.millimeters)
        let feet = m.converted(to: UnitLength.feet)
        let inches = m.converted(to: UnitLength.inches)
        
        //2. Add Them To Our Array & Return
        measurements.append(m)
        measurements.append(cm)
        measurements.append(mm)
        measurements.append(feet)
        measurements.append(inches)
        
        return measurements
    }
    
    /// Calculates The Angle In Degrees From Three Vectors
    ///
    /// - Parameters:
    ///   - start: GLKVector3
    ///   - mid: GLKVector3
    ///   - end: GLKVector3
    /// - Returns: Double
    func angleFromVectors(start: GLKVector3, mid: GLKVector3, end: GLKVector3) -> Double {
        
        //* Based On The Following Solution https://lonelycoding.com/angle-between-3-points-in-3d-space/ *//
        
        let vector1 = GLKVector3Subtract(start, mid)
        let vector2 = GLKVector3Subtract(end, mid)
        
        let vector1Normalized = GLKVector3Normalize(vector1)
        let vector2Normalized = GLKVector3Normalize(vector2)
        
        let result = vector1Normalized.x * vector2Normalized.x + vector1Normalized.y * vector2Normalized.y + vector1Normalized.z * vector2Normalized.z
        let angle: Double = Double(GLKMathRadiansToDegrees(acos(result)))
        
        return angle
    }
    
    func positionalNodes(joiningNodes: Bool, nodes: [SCNNode]) -> (nodeA: SCNNode, nodeB: SCNNode)?{
        
        var nodeA:SCNNode!
        var nodeB:SCNNode!
        
        //1. If We Are Joining Nodes (Creating A Shape) Get The Last & First Nodes
        if joiningNodes{
            
            guard let lastMarkerNode = nodes.last,
                  let firstMarkerNode = nodes.first else { return nil }
            
            nodeA = firstMarkerNode
            nodeB = lastMarkerNode
            
        }else{
            
            //2. Else Get The Last & Penultimate Nodes To Measure
            guard let lastMarkerNode = nodes.last else { return nil }
            let penultimateMarkerNode = nodes[nodes.count-2]
            
            nodeA = lastMarkerNode
            nodeB = penultimateMarkerNode
        }
    
        return (nodeA, nodeB)
    }
    
  
    /// Calculates The Distance Between Two SCNNodes
    ///
    /// - Parameter joiningNodes: Bool (Joins The Last Node Added To The First)
    /// - Returns: (distance: Float, nodeA: GLKVector3, nodeB: GLKVector3)
    func calculateDistanceBetweenNodes(joiningNodes: Bool, nodes: [SCNNode]) -> (distance: Float, nodeA: GLKVector3, nodeB: GLKVector3)?{
        
        guard let nodes = positionalNodes(joiningNodes: joiningNodes, nodes: nodes) else { return nil }
        let nodeA = nodes.nodeA
        let nodeB = nodes.nodeB
        
        //3. Convert The SCNVector3 Positions To GLKVector3
        let nodeAVector3 = GLKVector3Make(nodeA.position.x, nodeA.position.y, nodeA.position.z)
        let nodeBVector3 = GLKVector3Make(nodeB.position.x, nodeB.position.y, nodeB.position.z)
        
        //4. Calculate The Distance
        let distance = GLKVector3Distance(nodeAVector3, nodeBVector3)
        let meters = Measurement(value: Double(distance), unit: UnitLength.meters)
        print("Distance Between Markers Nodes = \(String(format: "%.2f", meters.value))m")
        
        //4. Return The Distance A Positions Of The Nodes
        return (distance: distance , nodeA: nodeAVector3, nodeB: nodeBVector3)
        
    }
    
    
    /// Calculates The Final Two Angles Of The Shape Constructed
    ///
    /// - Parameter nodes: [SCNNode]
    /// - Returns: (midNode: SCNNode, angle: Double)?
    func calculateFinalAnglesBetweenNodes(_ nodes: [SCNNode]) -> (midNode: SCNNode, angle: Double)?{
        
        //1. If A Shape With An Even Number Of Markers Has Been Created Then Perform The Following Calculation
        if nodes.count % 2 == 0{

            guard let firstNode = nodes.last,
            let midNode = nodes.first  else { return nil }
            let endNode = nodes[1]
            
            let angle = angleFromVectors(start: SCNVector3ToGLKVector3(firstNode.position),
                                         mid: SCNVector3ToGLKVector3(midNode.position),
                                         end: SCNVector3ToGLKVector3(endNode.position))
            
            return (midNode: midNode, angle: angle)
            
        }else{
        
            //2. A Shape With An Odd Number Of Markers Has Been Created
            guard let firstNode = nodes.last,
            let midNode = nodes.first  else { return nil }
            let endNode = nodes[1]
            
            let angle = angleFromVectors(start: SCNVector3ToGLKVector3(firstNode.position),
                                         mid: SCNVector3ToGLKVector3(midNode.position),
                                         end: SCNVector3ToGLKVector3(endNode.position))
            
            return (midNode: midNode, angle: angle)
        }
       
    }
    
    /// Calculates The Angle Between Three SCNNodes
    ///
    /// - Parameter nodes: [SCNNode]
    /// - Returns: (midNode: SCNNode, angle: Double)?
    func calculateAnglesBetweenNodes(joiningNodes: Bool, nodes: [SCNNode]) -> (midNode: SCNNode, angle: Double)?{
        
        //1. If The User Has Chosen To Join The Markers E.g. Make A Shape Then Get The Angle
        if joiningNodes{
            
            guard let firstNode = nodes.first else { return nil }
            let midNode = nodes[nodes.count-1]
            let endNode = nodes[nodes.count - 2]
            
            let angle = angleFromVectors(start: SCNVector3ToGLKVector3(firstNode.position),
                                         mid: SCNVector3ToGLKVector3(midNode.position),
                                         end: SCNVector3ToGLKVector3(endNode.position))
            
          
         
            //a. Return The Middle Node For Placing An Angle Label & The Angle Itself
            return (midNode: midNode, angle: angle)
          
        }else{
            
            //1. An Angle Can Only Be Calculated If We Have Three Nodes On Screen
            if nodes.count >= 3{
                
                //a. Get The Last Three Nodes From Our NodesAdded Array
                let firstNode = nodes[nodes.count - 3]
                let midNode = nodes[nodes.count-2]
                guard let endNode = nodes.last else { return nil }
                
                //b. Calculate The Angle Between Our Nodes
                let angle = angleFromVectors(start: SCNVector3ToGLKVector3(firstNode.position),
                                             mid: SCNVector3ToGLKVector3(midNode.position),
                                             end: SCNVector3ToGLKVector3(endNode.position))
                
                print("Angle Between Markers Nodes = \(String(format: "%.2f°", angle))")
                
                //c. Return The Middle Node For Placing An Angle Label & The Angle Itself
                return (midNode: midNode, angle: angle)
            }
        }

        return nil
        
    }
    
}
