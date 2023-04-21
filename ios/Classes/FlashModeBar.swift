//
//  FlashModeBar.swift
//  cheban_camera
//
//  Created by melody on 2023/4/18.
//

import Foundation

enum FlashMode: Int {
    case off
    case auto
    case on
    case open
}

class FlashModeBar: UIView {
    
    var selectFlashModeHandler: (_ flashMode: FlashMode) -> Void = { _ in }
    
    lazy var stackView: UIStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.axis = .horizontal
        $0.distribution = .fillEqually
        $0.spacing = 36.fixed
        addSubview($0)
        return $0
    }(UIStackView())
    
    lazy var separatorView: UIView = {
        $0.backgroundColor = .white
        $0.translatesAutoresizingMaskIntoConstraints = false
        addSubview($0)
        return $0
    }(UIView())
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 26
        layer.masksToBounds = true
        backgroundColor = .black.withAlphaComponent(0.65)
        let modes = [FlashMode.off, FlashMode.auto, FlashMode.on]
        modes.forEach { m in
            let item = renderItem(m);
            stackView.addArrangedSubview(item)
            NSLayoutConstraint.activate([
                item.widthAnchor.constraint(equalToConstant: 28.fixed),
                item.heightAnchor.constraint(equalToConstant: 28.fixed),
            ])
        }
        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 21.fixed),
            stackView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            
            separatorView.widthAnchor.constraint(equalToConstant: 0.5.fixed),
            separatorView.heightAnchor.constraint(equalToConstant: 36.fixed),
            separatorView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            separatorView.leftAnchor.constraint(equalTo: stackView.rightAnchor, constant: 32.fixed),
            separatorView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -58.fixed)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func renderItem(_ flashMode: FlashMode) -> UIView {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        switch (flashMode) {
        case .off:
            button.setImage(sourceImage(name: "flash_off"), for: .normal)
        case .auto:
            button.setImage(sourceImage(name: "flash_auto"), for: .normal)
        case .on:
            button.setImage(sourceImage(name: "flash_on"), for: .normal)
        case .open:
            button.setImage(sourceImage(name: "filter"), for: .normal)
        }
        button.tag = flashMode.rawValue
        button.addTarget(self, action: #selector(clickFlashMode), for: .touchUpInside)
        return button
    }
    
    @objc func clickFlashMode(_ sender: UIButton) {
        selectFlashModeHandler(FlashMode(rawValue: sender.tag) ?? FlashMode.off)
    }
    
}
