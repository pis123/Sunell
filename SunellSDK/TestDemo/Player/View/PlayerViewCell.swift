//
//  PlayerViewCell.swift
//  TestDemo
//
//  Created by Sunell on 2026/3/30.
//

import UIKit

/// 预览区域：使用**普通** `UIView` 根 layer + **子** `CAEAGLLayer` 承载 OpenGL。
/// 避免 `layerClass == CAEAGLLayer` 时，SDK 在 `render_thread` 里绑定 drawable 被 UIKit 严格判定为
/// “在修改视图根 layer”（仍可能告警，但比根 layer 为 EAGL 更稳妥；根本修复需 SDK 在主线程绑定或改用 Metal/VT）。
class PlayerViewCell: UIView {

    /// 传给 SDK 的绘制 surface（子 layer，非 `self.layer`）。
    let glLayer = CAEAGLLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGLSublayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGLSublayer()
    }

    private func setupGLSublayer() {
        glLayer.isOpaque = true
        glLayer.contentsScale = UIScreen.main.scale
        glLayer.drawableProperties = [
            kEAGLDrawablePropertyRetainedBacking as String: false,
            kEAGLDrawablePropertyColorFormat as String: kEAGLColorFormatRGBA8
        ]
        layer.addSublayer(glLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        glLayer.frame = bounds
    }
    deinit {
        print("PlayerViewCell deinit")
    }
}
