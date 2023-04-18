//
//  TakeshotButton.swift
//  cheban_camera
//
//  Created by melody on 2023/4/18.
//

import Foundation

class TakeshotButton: UIView {
    
    lazy var touchControl: UIControl = {
        $0.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
        $0.translatesAutoresizingMaskIntoConstraints = false
        addSubview($0);
        return $0;
    }(UIControl())
      
    lazy var takeshotTransformView: UIView = {
        $0.frame = CGRect(x: 6.fixed, y: 6.fixed, width: 60.fixed, height: 60.fixed)
        $0.layer.cornerRadius = 30.fixed
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = .white
        addSubview($0)
        return $0
    }(UIView())
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        layer.borderWidth = 6.fixed
        layer.cornerRadius = 36.fixed
        layer.masksToBounds = true
        NSLayoutConstraint.activate([
            takeshotTransformView.topAnchor.constraint(equalTo: self.topAnchor, constant: 6.fixed),
            takeshotTransformView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 6.fixed),
            takeshotTransformView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -6.fixed),
            takeshotTransformView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -6.fixed),
            touchControl.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 1.0),
            touchControl.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1.0),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addTarget(_ target: Any, action: Selector) {
        touchControl.addTarget(target, action: action, for: .touchUpInside);
    }
    
}
