//
//  RoundButton.swift
//  ARMeasure
//
//  Created by Josh Robbins on 19/05/2018.
//  Copyright © 2018 BlackMirrorz. All rights reserved.
//

import UIKit

@IBDesignable class RoundButton: UIButton {
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        refresh()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        refresh()
    }
    
    override func prepareForInterfaceBuilder() {
        refresh()
    }
    
    func refresh() {
        refreshCorners(value: cornerRadius)
        refreshLineColour(value: lineColour)
    }
    
    @IBInspectable var cornerRadius: CGFloat = 15 {
        didSet {
            refreshCorners(value: cornerRadius)
        }
    }
    
    @IBInspectable var lineColour: UIColor = UIColor.black {
        didSet {
            refreshLineColour(value: lineColour)
        }
    }
    
    func refreshCorners(value: CGFloat) {
        layer.cornerRadius = value
    }
    
    func refreshLineColour(value: UIColor) {
        layer.borderColor = value.cgColor
        layer.borderWidth = 1
    }
}
