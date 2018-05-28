//
//  ViewController.swift
//  ARMeasure
//
//  Created by Josh Robbins on 12/05/2018.
//  Copyright © 2018 BlackMirrorz. All rights reserved.
//

import UIKit
import ARKit

//-----------------------
//MARK: ARSCNViewDelegate
//-----------------------

extension ViewController: ARSCNViewDelegate{
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        //3. Update Our Status View
        DispatchQueue.main.async {
            
            //1. Update The Tracking Status
            self.statusLabel.text = self.augmentedRealitySession.sessionStatus()
            
            //2. If We Have Nothing To Report Then Hide The Status View & Shift The Settings Menu
            if let validSessionText = self.statusLabel.text{
                
                self.sessionLabelView.isHidden = validSessionText.isEmpty
            }
            
            if self.sessionLabelView.isHidden { self.settingsConstraint.constant = 26 } else { self.settingsConstraint.constant = 0 }
           
        }
    }
}

class ViewController: UIViewController {

    //1. Create A Reference To Our ARSCNView In Our Storyboard Which Displays The Camera Feed
    @IBOutlet weak var augmentedRealityView: ARSCNView!
    
    //2. Create A Reference To Our ARSCNView In Our Storyboard Which Will Display The ARSession Tracking Status
    @IBOutlet weak var sessionLabelView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    
    //3. Create Our ARWorld Tracking Configuration
    let configuration = ARWorldTrackingConfiguration()
    
    //4. Create Our Session
    let augmentedRealitySession = ARSession()

    //5. Create Arrays To Store All The Nodes Placed
    var nodesAdded = [SCNNode]()
    var angleNodes = [SCNNode]()
    var distanceNodes = [SCNNode]()
    var lineNodes = [SCNNode]()
    var showDistanceLabels = true
    var showAngleLabels = false
    
    //6. Create A Variable Which Determines Whether The User Wants To Join The Last & First Markers Together
    var joiningNodes = false
    
    //7. Create An Array Of UILabels Which Will Display Our Length In Different Units
    @IBOutlet var measurementLabels: [UILabel]!
    @IBOutlet var unitHolder: UIView!
    
    //8. Settings Menu
    @IBOutlet var settingsMenu: UIView!
    @IBOutlet var settingsConstraint: NSLayoutConstraint!
    @IBOutlet var planeDetectionController: UISegmentedControl!
    @IBOutlet var festurePointController: UISegmentedControl!
    @IBOutlet var showAnglesController: UISegmentedControl!
    @IBOutlet var showDistanceController: UISegmentedControl!
    var settingsMenuShown = false
    
    //9. Variables To Determine If We Are Placing Our Markers On Detected Planes Or Feature Points
    var placeOnPlane = false
    var showFeaturePoints = false
    var placementType: ARHitTestResult.ResultType = .featurePoint
    
    //--------------------
    //MARK: View LifeCycle
    //--------------------
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        clearMeasurementLabels()
        
    }
    
    override func viewDidAppear(_ animated: Bool) { setupARSession() }
    
    override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }
    
    override var prefersStatusBarHidden: Bool { return true }
    
    //-------------
    //MARK: Actions
    //-------------
    
    /// Closes All The Node Markers To Form A Shape
    @IBAction func closeMarkers(){ closeNodes() }
    
    /// Removes All Measurement Data
    @IBAction func reset(){
        
        //1. Remove All Nodes From The Hierachy
        augmentedRealityView.scene.rootNode.enumerateChildNodes { (nodeToRemove, _) in nodeToRemove.removeFromParentNode() }
        
        //2. Clear The NodesAdded Array
        nodesAdded.removeAll()
        angleNodes.removeAll()
        distanceNodes.removeAll()
        lineNodes.removeAll()
        
        //3. Reset The Joining Boolean
        joiningNodes = false
        
        //4. Reset The Labels
        clearMeasurementLabels()
        settingsMenu.alpha = 0
        settingsMenuShown = false
    }
    
    //--------------
    //MARK: Settings
    //--------------

    /// Shows And Hides The Settings Menu
    @IBAction func showSettingsMenu(){
        
        var opacity: CGFloat = 0
        var angleOpacity: CGFloat = 0
        var markerOpacity: CGFloat = 0
        
        if settingsMenu.alpha == 0 {
            
            settingsMenu.alpha = 1
            settingsMenuShown = true
            augmentedRealityView.rippleView()
            
        } else {
            
            settingsMenu.alpha = 0
            settingsMenuShown = false
            opacity = 1
            
            if showAngleLabels { angleOpacity = 1 }
            if showDistanceLabels { markerOpacity = 1 }
            
        }
        
        setNodesVisibility(angleNodes, opacity: angleOpacity)
        setNodesVisibility(distanceNodes, opacity: markerOpacity)
        let markerAndLineNodes = lineNodes + nodesAdded
        setNodesVisibility(markerAndLineNodes, opacity: opacity)
    }
    
    /// Hides The 3D Distance Labels
    ///
    /// - Parameter controller: UISegmentedControl
    @IBAction func hideDistanceLabels(_ controller: UISegmentedControl){
   
        if controller.selectedSegmentIndex != 1 {
            
            showDistanceLabels = true
            
        }else{
            
            showDistanceLabels = false
        }
        
    }
    
    /// Hides The 3D Angle Labels
    ///
    /// - Parameter controller: UISegmentedControl
    @IBAction func hideAngleLabels(_ controller: UISegmentedControl){
        

        if controller.selectedSegmentIndex != 1 {
            
            showAngleLabels = true
            
        }else{
            showAngleLabels = false
        }
            
    }
    
    /// Determines Whether The VideoNode Should Be Placed Using Plane Detection
    ///
    /// - Parameter controller: UISegmentedControl
    @IBAction func setPlaneDetection(_ controller: UISegmentedControl){
        
        if controller.selectedSegmentIndex == 1 { placeOnPlane = false } else { placeOnPlane = true }
        
        setupSessionPreferences()
    }
    
    /// Determines Whether The User Should Be Able To See FeaturePoints
    ///
    /// - Parameter controller: UISegmentedControl
    @IBAction func setFeaturePoints(_ controller: UISegmentedControl){
        
        if controller.selectedSegmentIndex == 1 { showFeaturePoints = false } else { showFeaturePoints = true }
        setupSessionPreferences()
    }
    
    //----------------------
    //MARK: Marker Placement
    //----------------------
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if joiningNodes { reset() }
        
        if settingsMenuShown { return }
        
        //1. Perform An ARHitTest To Search For Any Existing Planes Or Feature Points
        if placeOnPlane { placementType = .existingPlane } else { placementType = .featurePoint }
        
        //2. Get The Current Touch Location & Perform An ARHitTest
        guard let currentTouchLocation = touches.first?.location(in: self.augmentedRealityView),
              let hitTest = self.augmentedRealityView.hitTest(currentTouchLocation, types: placementType ).last else { return }
        
        //3. Add A Marker Node
        addMarkerNodeFromMatrix(hitTest.worldTransform)
        
    }
    

    /// Adds An SCNSphere At The Current Touch Location
    ///
    /// - Parameter matrix: matrix_float4x4
    func addMarkerNodeFromMatrix(_ matrix: matrix_float4x4){
    
        //1. Create The Marker Node & Add It  To The Scene
        let markerNode = MarkerNode(fromMatrix: matrix)
        self.augmentedRealityView.scene.rootNode.addChildNode(markerNode)
        
        //3. Add It To Our NodesAdded Array
        nodesAdded.append(markerNode)
        
        //4. Perform Any Calculations Needed
        getDistanceBetweenNodes(needsJoining: joiningNodes)
    
        guard let angleResult = calculateAnglesBetweenNodes(joiningNodes: joiningNodes, nodes: nodesAdded) else { return }
        createAngleNodeLabelOn(angleResult.midNode, angle: angleResult.angle)

    }
    
    /// Joins The Last & First Nodes
    func closeNodes(){
    
        joiningNodes = true
        getDistanceBetweenNodes(needsJoining: joiningNodes)
        
        guard let angleResult = calculateAnglesBetweenNodes(joiningNodes: joiningNodes, nodes: nodesAdded) else { return }
        createAngleNodeLabelOn(angleResult.midNode, angle: angleResult.angle)
        
        guard let angleResultB = calculateFinalAnglesBetweenNodes(nodesAdded) else { return }
        createAngleNodeLabelOn(angleResultB.midNode, angle: angleResultB.angle)
     
    }
    
    //-------------------------------------------
    //MARK: Calculation + Distance & Angle Labels
    //-------------------------------------------
    
    /// Calculates The Distance Between 2 SCNNodes
    func getDistanceBetweenNodes(needsJoining: Bool){
        
        //1. If We Have More Than Two Nodes On Screen We Can Calculate The Distance Between Them
        if nodesAdded.count >= 2{
            
            guard let result = calculateDistanceBetweenNodes(joiningNodes: needsJoining, nodes: nodesAdded) else { return }
            
            //2. Draw A Line Between The Nodes
            let line = MeasuringLineNode(startingVector: result.nodeA, endingVector: result.nodeB)
            self.augmentedRealityView.scene.rootNode.addChildNode(line)
            lineNodes.append(line)
            
            //3. Create The Distance Label
            createDistanceLabel(joiningNodes: needsJoining, nodes: nodesAdded, distance: result.distance)
        }
        
    }
    
    /// Creates An Angle Label Between Three SCNNodes
    ///
    /// - Parameters:
    ///   - node: SCNNode
    ///   - angle: Double
    func createAngleNodeLabelOn(_ node: SCNNode, angle: Double){
        
        //1. Format Our Angle
        let formattedAngle = String(format: "%.2f°", angle)
        
        //2. Create The Angle Label & Add It To The Corresponding Node
        let angleText = TextNode(text: formattedAngle, colour: .white)
        angleText.position = SCNVector3(0, 0.01, 0)
        node.addChildNode(angleText)
        
        //3. Store It
        angleNodes.append(angleText)
        
        var opacity: CGFloat = 0
        
        if showAngleLabels { opacity = 1 }
        setNodesVisibility(angleNodes, opacity: opacity)
    }
    
    /// Clears The Measurement Labels
    func clearMeasurementLabels(){
        
        measurementLabels.forEach{ $0.text = "" }
        unitHolder.alpha = 0
    }
    
    /// Creates A Distance Label Between Two SCNNodes
    ///
    /// - Parameters:
    ///   - joiningNodes: Bool (Joins The Last Node Added To The First)
    ///   - nodes: [SCNNode]
    ///   - distance: Float
    func createDistanceLabel(joiningNodes: Bool, nodes: [SCNNode], distance: Float){
        
        //1. Get The Nodes Used For Postioning
        guard let nodes = positionalNodes(joiningNodes: joiningNodes, nodes: nodes) else { return }
        let nodeA = nodes.nodeA
        let nodeB = nodes.nodeB
        
        //2. Format Our Angle
        let formattedDistance = String(format: "%.2f", distance)
   
        //4. Create The Distance Label & Add It To The Scene
        let distanceLabel = TextNode(text: "\(formattedDistance)m", colour: .white)
        distanceLabel.placeBetweenNodes(nodeA, and: nodeB)
        self.augmentedRealityView.scene.rootNode.addChildNode(distanceLabel)
        
        //5. Generate The Measurement Labels
        generateMeasurementLabelsFrom(distance)
        
        //6. Store It
        distanceNodes.append(distanceLabel)
        
        var opacity: CGFloat = 0
        
        if showDistanceLabels { opacity = 1 }
        setNodesVisibility(distanceNodes, opacity: opacity)
    }
    
    func generateMeasurementLabelsFrom(_ distanceInMetres: Float){
        
        let sequence = stride(from: 0, to: 5, by: 1)
        let measurements = convertedLengthsFromMetres(distanceInMetres)
    
        let suffixes = ["m", "cm", "mm", "ft", "in"]
        
        for index in sequence {
         
            let labelToDisplay = measurementLabels[index]
            let value = "\(String(format: "%.2f", measurements[index].value))\(suffixes[index])"
            labelToDisplay.text = value
        }
        
        unitHolder.alpha = 1
        
    }
    
    //---------------------
    //MARK: Node Visibility
    //---------------------
    
    
    /// Sets The Visibility Of The Angle & Distance Text Nodes
    ///
    /// - Parameters:
    ///   - nodes: [SCNNode]
    ///   - opacity: CGFloat
    func setNodesVisibility(_ nodes: [SCNNode], opacity: CGFloat) {
        
        nodes.forEach { (node) in node.opacity = opacity }
    
    }
    
    //---------------
    //MARK: ARSession
    //---------------
    
    /// Sets Up The ARSession
    func setupARSession(){
        
        //1. Set The AR Session
        augmentedRealityView.session = augmentedRealitySession
        augmentedRealityView.delegate = self
        setupSessionPreferences()
        
    }
    
    /// Runs The ARSessionConfiguration Based On The Preferences Chosen
    func setupSessionPreferences(){
        
        configuration.planeDetection = [planeDetection(.None)]
        augmentedRealityView.debugOptions = debug(.None)
        
        if placeOnPlane { configuration.planeDetection = [planeDetection(.Both)] }
        
        if showFeaturePoints { augmentedRealityView.debugOptions = debug(.FeaturePoints) }
        
        //4. Run The Session & Reset The Video Node
        augmentedRealitySession.run(configuration, options: runOptions(.ResetAndRemove))
        reset()
      
    }

}

