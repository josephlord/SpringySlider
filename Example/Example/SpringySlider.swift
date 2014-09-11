//
//  Slider.swift
//  Example
//
//  Created by Wojciech Lukaszuk on 06/09/14.
//  Copyright (c) 2014 Wojtek Lukaszuk. All rights reserved.
//

import UIKit
import QuartzCore
import Foundation

@IBDesignable class SpringySlider: UIControl
{
    private let trackLayerHeight: CGFloat = 4.0
    private let maxTiltAngle: CGFloat = CGFloat(M_PI/5)
    private var thumbLayer: CAShapeLayer = CAShapeLayer()
    private var minTrackLayer: CALayer = CALayer()
    private var maxTrackLayer: CALayer = CALayer()
    private var previousTouchPoint: CGPoint = CGPointZero
    
    private enum Direction {
        case Left
        case Right
    }
    
    private var trackLayerWidth: CGFloat {
        return self.bounds.size.width
    }
    
    internal var value: CGFloat = 0.5 {
        didSet {
            self.thumbLayer.position.x = self.value * self.bounds.width
            self.minTrackLayer.frame.size.width = self.value * self.bounds.width
        }
    }
    
    @IBInspectable internal var thumbTintColor: UIColor = UIColor.whiteColor() {
        didSet {
            self.thumbLayer.fillColor = self.thumbTintColor.CGColor
        }
    }
    
    @IBInspectable internal var trackTintColor: UIColor = UIColor.whiteColor()  {
        didSet {
            self.minTrackLayer.backgroundColor = self.trackTintColor.CGColor
            self.maxTrackLayer.backgroundColor = self.trackTintColor.colorWithAlphaComponent(0.5).CGColor
        }
    }
    
    @IBInspectable internal var thumbImage: UIImage? {
        didSet {
            self.thumbLayer.contents = thumbImage!.CGImage
            self.thumbLayer.frame.size = thumbImage!.size
            self.thumbLayer.position = CGPointMake(self.value * self.trackLayerWidth, self.trackLayerHeight)
            self.thumbLayer.path = nil
        }
    }
    
    // MARK: initialization
    
    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        self.setup()
    }
    
    private func setup() -> ()
    {
        self.maxTrackLayer = CALayer()
        self.maxTrackLayer.frame = CGRectMake(0, 0, self.trackLayerWidth, self.trackLayerHeight)
        self.maxTrackLayer.backgroundColor = self.trackTintColor.colorWithAlphaComponent(0.5).CGColor
        self.layer.addSublayer(self.maxTrackLayer)
        
        self.minTrackLayer = CALayer()
        self.minTrackLayer.frame = CGRectMake(0, 0, self.value * self.trackLayerWidth, self.trackLayerHeight)
        self.minTrackLayer.backgroundColor = self.trackTintColor.CGColor
        self.layer.addSublayer(self.minTrackLayer)
        
        self.thumbLayer = CAShapeLayer()
        self.thumbLayer.frame = CGRectMake(0, 0, 85, 102)
        self.thumbLayer.path = self.defaultThumbMaskPath()
        self.thumbLayer.fillColor = self.thumbTintColor.CGColor
        self.thumbLayer.anchorPoint = CGPoint(x: 0.5, y: 0)
        self.thumbLayer.position = CGPointMake(self.value * self.trackLayerWidth, self.trackLayerHeight)
        self.layer.addSublayer(self.thumbLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.maxTrackLayer.frame = CGRectMake(0, 0, self.trackLayerWidth, self.trackLayerHeight)
        self.minTrackLayer.frame = CGRectMake(0, 0, self.value * self.trackLayerWidth, self.trackLayerHeight)
        self.thumbLayer.position = CGPointMake(self.value * self.trackLayerWidth, self.trackLayerHeight)
    }
    
    // MARK: tracking behaviour
    
    override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent) -> Bool
    {
        previousTouchPoint = touch.locationInView(self)
        
        if CGRectContainsPoint(self.thumbLayer.frame, previousTouchPoint) {
            
            self.thumbLayer.transform = self.thumbLayer.presentationLayer().transform
            self.thumbLayer.removeAllAnimations()
            
            return true
        }
        
        return false
    }
    
    override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent) -> Bool
    {
        var touchPoint = touch.locationInView(self)
        var deltaX: CGFloat = touchPoint.x - previousTouchPoint.x
        self.previousTouchPoint = touchPoint
        var currentTiltAngle: CGFloat = thumbLayer.valueForKeyPath("transform.rotation.z") as CGFloat
        
        var direction = Direction.Right
        var maxTiltAngle: CGFloat = -self.maxTiltAngle
        
        if deltaX < 0 {
            direction = Direction.Left
            maxTiltAngle = self.maxTiltAngle
        }
        
        if !self.isMaxTitled(direction, angle: currentTiltAngle) {
            
            var transform: CATransform3D = CATransform3DRotate(self.thumbLayer.transform, CGFloat(-M_PI/180) * deltaX, 0, 0, 1)
            
            var calculatedTitlAngle: CGFloat = atan2(transform.m12, transform.m11);
            
            if self.isMaxTitled(direction, angle: calculatedTitlAngle) {
                transform = CATransform3DRotate(CATransform3DIdentity, maxTiltAngle, 0, 0, 1)
            }
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            
            self.thumbLayer.transform = transform
            
            CATransaction.commit()
            
        } else {
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            
            var newValue = (self.thumbLayer.position.x + deltaX) / self.trackLayerWidth
            self.value = min(max(newValue, 0.0), 1.0)
            
            CATransaction.commit()
        }
        
        return true
    }
    
    override func endTrackingWithTouch(touch: UITouch, withEvent event: UIEvent)
    {
        self.thumbSpringAnimation()
        self.sendActionsForControlEvents(UIControlEvents.ValueChanged)
    }
    
    override func cancelTrackingWithEvent(event: UIEvent?)
    {
        self.thumbSpringAnimation()
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool
    {
        if CGRectContainsPoint(self.thumbLayer.frame, point) {
            return true
        }
        
        return super.pointInside(point, withEvent: event)
    }
    
    // MARK: helpers
    
    private func isMaxTitled(direction : Direction, angle: CGFloat) -> Bool
    {
        switch(direction) {
            
        case .Left:
            return angle >= self.maxTiltAngle
        case .Right:
            return angle <= -self.maxTiltAngle
        }
    }
    
    private func thumbSpringAnimation() -> ()
    {
        var animation = SpringAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = self.thumbLayer.transform.rotationZ();
        animation.toValue = 0;
        self.thumbLayer.addAnimation(animation, forKey: nil)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        self.thumbLayer.transform = CATransform3DIdentity
        
        CATransaction.commit()
    }
    
    private func defaultThumbMaskPath() -> CGPath
    {
        var bezierPath = UIBezierPath()
        bezierPath.moveToPoint(CGPointMake(53, 18))
        bezierPath.addLineToPoint(CGPointMake(42, 0))
        bezierPath.addLineToPoint(CGPointMake(31, 18))
        bezierPath.addCurveToPoint(CGPointMake(0, 59), controlPoint1: CGPointMake(13, 22), controlPoint2: CGPointMake(0, 39))
        bezierPath.addCurveToPoint(CGPointMake(42, 102), controlPoint1: CGPointMake(0, 82), controlPoint2: CGPointMake(19, 102))
        bezierPath.addCurveToPoint(CGPointMake(85, 59), controlPoint1: CGPointMake(65, 102), controlPoint2: CGPointMake(85, 82))
        bezierPath.addCurveToPoint(CGPointMake(53, 18), controlPoint1: CGPointMake(85, 39), controlPoint2: CGPointMake(71, 22))
        bezierPath.closePath()
        bezierPath.moveToPoint(CGPointMake(42, 96))
        bezierPath.addCurveToPoint(CGPointMake(5, 59), controlPoint1: CGPointMake(22, 96), controlPoint2: CGPointMake(5, 79))
        bezierPath.addCurveToPoint(CGPointMake(42, 22), controlPoint1: CGPointMake(5, 39), controlPoint2: CGPointMake(22, 22))
        bezierPath.addCurveToPoint(CGPointMake(79, 59), controlPoint1: CGPointMake(62, 22), controlPoint2: CGPointMake(79, 39))
        bezierPath.addCurveToPoint(CGPointMake(42, 96), controlPoint1: CGPointMake(79, 79), controlPoint2: CGPointMake(62, 96))
        bezierPath.closePath()
        
        return bezierPath.CGPath
    }
}

extension CATransform3D
{
    func rotationZ() -> CGFloat
    {
        return atan2(self.m12, self.m11)
    }
}