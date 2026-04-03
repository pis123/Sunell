//
//  PlayerViewCell.swift
//  TestDemo
//
//  Created by Sunell on 2026/3/30.
//

import UIKit

class PlayerViewCell: UIView {

    override class var layerClass: AnyClass {
        CAEAGLLayer.self
    }

    var glLayer: CAEAGLLayer {
        layer as! CAEAGLLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    private func setupLayer() {
        glLayer.isOpaque = true
        glLayer.contentsScale = UIScreen.main.scale
        glLayer.drawableProperties = [
            kEAGLDrawablePropertyRetainedBacking as String: false,
            kEAGLDrawablePropertyColorFormat as String: kEAGLColorFormatRGBA8
        ]
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        glLayer.frame = bounds
    }

}
