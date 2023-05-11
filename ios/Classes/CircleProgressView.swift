//
//  CircleProgressView.swift
//  cheban_camera
//
//  Created by melody on 2023/4/18.
//

import Foundation

class CircleProgressView: UIView, CAAnimationDelegate {
    
    /// 轨迹
    var trackLayer: CAShapeLayer!
   
    /// 进度
    var progressLayer: CAShapeLayer!
    
    var animationDelegate: CAAnimationDelegate?
    
    var trackColor: UIColor = .white.withAlphaComponent(0.2)
        
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if (trackLayer == nil) {
            trackLayer = buildLayer(trackColor)
            let path = buildPath(1.0, trackLayer.lineWidth)
            trackLayer.path = path.cgPath
            trackLayer.strokeStart = 0
            trackLayer.strokeEnd = 1
            self.layer.addSublayer(trackLayer)
        }
        if (progressLayer == nil) {
            progressLayer = buildLayer(.red)
            let path = buildPath(1.0, progressLayer.lineWidth)
            progressLayer.path = path.cgPath
            progressLayer.strokeStart = 0
            progressLayer.strokeEnd = 0
            self.layer.addSublayer(progressLayer)
        }
    }
    
    func startAnimation() {
        let progressAnimation: CABasicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        progressAnimation.fromValue = 0
        progressAnimation.toValue = 1
        progressAnimation.duration = 30
        progressAnimation.isRemovedOnCompletion = false
        progressAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        progressAnimation.fillMode = .forwards
        progressAnimation.delegate = self
        progressLayer.add(progressAnimation, forKey: "progress")
    }
    
    func stopAnimation() {
        progressLayer.strokeEnd = 0
        progressLayer.removeAllAnimations()
    }
    
    private func buildLayer(_ color: UIColor) -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.lineWidth = 6.fixed
        layer.lineCap = .round
        layer.lineJoin = .round
        layer.strokeColor = color.cgColor
        layer.strokeStart = 0;
        layer.strokeEnd = 0;
        layer.fillColor = UIColor.clear.cgColor
        return layer
    }
    
    private func buildPath(_ progress: Double, _ lineWidth: Double) -> UIBezierPath {
        let endAngle = -CGFloat.pi / 2 + (CGFloat.pi * 2) * CGFloat(progress)
        let radius = self.bounds.width / 2 - lineWidth
        let path = UIBezierPath(arcCenter: CGPoint(x: bounds.width / 2, y: bounds.height / 2), radius: radius, startAngle: -CGFloat.pi / 2, endAngle: endAngle, clockwise: true)
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        return path
    }
    
    func animationDidStart(_ anim: CAAnimation) {
        self.animationDelegate?.animationDidStart?(anim)
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.animationDelegate?.animationDidStop?(anim, finished: flag)
    }
    
}
