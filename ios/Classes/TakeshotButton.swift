//
//  TakeshotButton.swift
//  cheban_camera
//
//  Created by melody on 2023/4/18.
//

import Foundation

class TakeshotButton: UIView, CAAnimationDelegate {
    
    var takeshotShouldCapture: () -> Void = {}
    var takeshotShouldRecordMovie: (_ isStart: Bool) -> Void = { _ in }
    var takeshotUpdateRecordMovie: (_ countdown: Int) -> Void = { _ in }
    
    var timer : Timer?
    var countdown : Int = 0
    var sourceType: Int = 3
    
    lazy var circleProgressView: CircleProgressView = {
        $0.animationDelegate = self
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.isUserInteractionEnabled = true
        $0.trackColor = sourceType == 1 ? .white : .white.withAlphaComponent(0.2)
        addSubview($0)
        return $0
    }(CircleProgressView())
              
    lazy var takeshotTransformView: UIView = {
        $0.layer.cornerRadius = 28.fixed
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.isUserInteractionEnabled = true
        $0.backgroundColor = .white
        addSubview($0)
        return $0
    }(UIView())
    
    init(frame: CGRect, sourceType: Int) {
        super.init(frame: frame)
        self.sourceType = sourceType
        isUserInteractionEnabled = true
        NSLayoutConstraint.activate([
            circleProgressView.widthAnchor.constraint(equalTo: self.widthAnchor),
            circleProgressView.heightAnchor.constraint(equalTo: self.heightAnchor),
            takeshotTransformView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            takeshotTransformView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            takeshotTransformView.widthAnchor.constraint(equalToConstant: 56.fixed),
            takeshotTransformView.heightAnchor.constraint(equalToConstant: 56.fixed)
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTakeshotPressed))
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(onTakeshotLongPressed))
        addGestureRecognizer(tap)
        addGestureRecognizer(longPress)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func fireTimer() {
        invalidTimer()
        countdown = 0
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(onTimerUpdate), userInfo: nil, repeats: true)
        timer?.fire()
    }

    func invalidTimer() {
        print("invalidTimer")
        timer?.invalidate()
        timer = nil
    }
    
    func updateTransformView(_ animated: Bool) {
        NSLayoutConstraint.deactivate(takeshotTransformView.constraints)
        if (animated) {
            takeshotTransformView.layer.cornerRadius = 8.fixed
            NSLayoutConstraint.activate([
                takeshotTransformView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                takeshotTransformView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                takeshotTransformView.widthAnchor.constraint(equalToConstant: 16.fixed),
                takeshotTransformView.heightAnchor.constraint(equalToConstant: 16.fixed)
            ])
        } else {
            takeshotTransformView.layer.cornerRadius = 28.fixed
            NSLayoutConstraint.activate([
                takeshotTransformView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                takeshotTransformView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                takeshotTransformView.widthAnchor.constraint(equalToConstant: 56.fixed),
                takeshotTransformView.heightAnchor.constraint(equalToConstant: 56.fixed)
            ])
        }
    }
        
    @objc func onTakeshotPressed(_ recognizer: UITapGestureRecognizer) {
        takeshotShouldCapture()
    }
    
    @objc func onTakeshotLongPressed(_ recognizer: UILongPressGestureRecognizer) {
        if (sourceType == 1) {
            return
        }
        switch recognizer.state {
        case .began:
            circleProgressView.startAnimation()
            updateTransformView(true)
            fireTimer()
            takeshotShouldRecordMovie(true)
            break
        case .changed:
            break
        case .ended:
            circleProgressView.stopAnimation()
            updateTransformView(false)
            invalidTimer()
            takeshotShouldRecordMovie(false)
            break
        case .cancelled:
            circleProgressView.stopAnimation()
            updateTransformView(false)
            invalidTimer()
            takeshotShouldRecordMovie(false)
            break
        case .possible:
            break
        case .failed:
            circleProgressView.stopAnimation()
            updateTransformView(false)
            invalidTimer()
            takeshotShouldRecordMovie(false)
            break
        @unknown default:
            break
        }
    }
    
    @objc func onTimerUpdate(sender: Timer) {
        print(countdown)
        takeshotUpdateRecordMovie(countdown)
        countdown = countdown + 1
    }
    
    func animationDidStart(_ anim: CAAnimation) {
        
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        circleProgressView.stopAnimation()
        updateTransformView(false)
        takeshotShouldRecordMovie(false)
        invalidTimer()
    }
    
    deinit {
        invalidTimer()
    }
}
