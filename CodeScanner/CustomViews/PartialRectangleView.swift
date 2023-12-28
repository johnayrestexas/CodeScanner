//
//  PartialRectangleView.swift
//  CodeScanner
//
//  Created by John Ayres on 12/27/23.
//

import Foundation
import UIKit

/**
 This is a simple `UIView` that wraps a `CAShapeLayer` that draws a rounded rectangle shape with gaps at the sides.
 */
class PartialRectangleView: UIView {
    
    // MARK: - Private Properties
    private var shapeLayer: CAShapeLayer
    
    
    // MARK: - Constructors
    
    /**
     Initializes an returns a newly alloced `PartialRectangleView` object.
     
     - Parameters:
        - frame:  The frame rectangle for the view, measured in points. The origin of the frame is relative to the superview in which you plan to add it.
     
     - Returns: A newly initialized `PartialRectangleView` object.
     */
    override init(frame: CGRect) {
        shapeLayer = CAShapeLayer()
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        shapeLayer = CAShapeLayer()
        super.init(coder: coder)
        setup()
    }

    
    // MARK: - Overrides
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 10
        clipsToBounds = true
        
        shapeLayer.frame = bounds
        shapeLayer.path = path(for: bounds)
    }
    
    
    // MARK: - Private Methods
    
    /// Common setup code to initialize the view when it is created.
    private func setup() {
        shapeLayer.lineWidth = 2.0
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.lineCap = .square
        shapeLayer.lineJoin = .miter
        shapeLayer.fillColor = UIColor.clear.cgColor
        layer.addSublayer(shapeLayer)
    }
    
    /// Returns the path that draws the shape.
    private func path(for rect: CGRect) -> CGPath {
        let scale: CGFloat = 0.2
        let path = CGMutablePath()
        
        let topLeftY = CGPoint(x: 0, y: rect.height * scale)
        let topLeftX = CGPoint(x: rect.width * scale, y: 0)
        
        path.move(to: topLeftY)
        path.addArc(tangent1End: CGPoint.zero, tangent2End: topLeftX, radius: 10)
        path.addLine(to: topLeftX)
        
        let bottomLeftY = CGPoint(x: 0, y: rect.height - rect.height * scale)
        let bottomLeftX = CGPoint(x: rect.width * scale, y: rect.height)

        path.move(to: bottomLeftY)
        path.addArc(tangent1End: CGPoint(x: 0, y: rect.height), tangent2End: bottomLeftX, radius: 10)
        path.addLine(to: bottomLeftX)

        let topRightY = CGPoint(x: rect.width, y: rect.height * scale)
        let topRightX = CGPoint(x: rect.width - rect.width * scale, y: 0)
        
        path.move(to: topRightY)
        path.addArc(tangent1End: CGPoint(x: rect.width, y: 0), tangent2End: topRightX, radius: 10)
        path.addLine(to: topRightX)

        let bottomRightY = CGPoint(x: rect.width, y: rect.height - rect.height * scale)
        let bottomRightX = CGPoint(x: rect.width - rect.width * scale, y: rect.height)
        
        path.move(to: bottomRightY)
        path.addArc(tangent1End: CGPoint(x: rect.width, y: rect.height), tangent2End: bottomRightX, radius: 10)
        path.addLine(to: bottomRightX)
        
        return UIBezierPath(cgPath: path).cgPath
    }
}
