//
//  PlayerView.swift
//  TestDemo
//
//  Created by Sunell on 2026/3/25.
//

import UIKit
import SunellSDK
//import OpenGLES


class PlayerView: UIView {

    var device: SunellDeviceModel {
        didSet {
            // 连接/能力回调常「换了一个 model 实例」但 deviceId、通道数未变；若每次都 rebuild，会拆掉正在渲染的 `CAEAGLLayer`，出现大量 PlayerViewCell deinit 甚至 GL 崩溃。
            let sameDevice = (oldValue.deviceId as String) == (device.deviceId as String)
            let sameLayout = sameDevice
                && Self.derivedCellCount(for: oldValue) == Self.derivedCellCount(for: device)
            if sameLayout {
                return
            }
            requestRebuildChannelCells()
        }
    }

    /// 与 `rebuildChannelCells` 中规则一致，用于判断是否需要物理重建 cell。
    private static func derivedCellCount(for d: SunellDeviceModel) -> Int {
        let raw = max(0, Int(d.chnNum))
        return raw == 0 ? 1 : raw
    }

    var bgScrollView = UIScrollView()
    /// One `PlayerViewCell` per channel; index matches channel order (0..<chnNum).
    private(set) var cellArray: [PlayerViewCell] = []

    /// 物理重建 cell 之前的回调钩子：业务方（`LivePlayerPage`）必须在这里
    /// 同步把当前 `glLayer` 摘下、并发起 `liveStop` + `closeGL`，等回调里调 `proceed()`
    /// 才允许真正重建。这样可以避免 SDK render_thread 仍持有旧 `CAEAGLLayer` 指针时
    /// cell 已经被 dealloc，最终在 `LayerAnimation::unref` 阶段崩溃。
    /// 形参 `proceed`：业务方完成 SDK 侧停流后必须在主线程调用一次。
    var willRebuildCells: ((_ proceed: @escaping () -> Void) -> Void)?
    /// 防止重入：钩子异步处理期间又触发 `device.didSet`。
    private var isRebuildingCells = false
    private var pendingRebuildAfterCurrent = false

    init(frame: CGRect, device: SunellDeviceModel) {
        self.device = device
        super.init(frame: frame)
        setUpSubView()
    }

    required init?(coder: NSCoder) {
        self.device = SunellDeviceModel()
        super.init(coder: coder)
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpSubView() {
        bgScrollView.showsHorizontalScrollIndicator = true
        bgScrollView.bounces = true
        addSubview(bgScrollView)
        // 初始化阶段不会有正在跑的 `liveStart`，可以直接同步重建（也未注册 `willRebuildCells`）。
        doRebuildChannelCells()
    }

    /// Page width matches visible width (fullscreen: screen width); before layout falls back to main screen width.
    private var pageWidth: CGFloat {
        let w = bounds.width
        return w > 0 ? w : UIScreen.main.bounds.width
    }

    /// Current horizontal page index; same as `cellArray` index.
    func currentPageIndex() -> Int {
        let w = pageWidth
        guard w > 0 else { return 0 }
        return Int(round(bgScrollView.contentOffset.x / w))
    }

    /// 按当前 `device` 重新生成 cell（例如连接成功后补全了 `devType`/`chnNum`，需与 `LivePlayerPage.device` 对齐）。
    /// 走 `requestRebuildChannelCells`，让业务方有机会先 `liveStop` + `closeGL`，再丢弃旧 `glLayer`。
    func reloadChannelCellsFromDevice() {
        requestRebuildChannelCells()
    }

    /// 入口：尝试重建 cell。如果业务方注册了 `willRebuildCells`，**必须等它回调 `proceed()`** 才会真正
    /// 拆视图；否则就退化为同步重建（用于尚未 `liveStart` 的初始化场景）。
    private func requestRebuildChannelCells() {
        guard !isRebuildingCells else {
            // 钩子异步处理过程中又触发了重建，留个标志，等当前回合 finish 时再走一遍。
            pendingRebuildAfterCurrent = true
            return
        }
        guard let willRebuildCells else {
            doRebuildChannelCells()
            return
        }
        isRebuildingCells = true
        willRebuildCells { [weak self] in
            guard let self else { return }
            self.doRebuildChannelCells()
            self.isRebuildingCells = false
            if self.pendingRebuildAfterCurrent {
                self.pendingRebuildAfterCurrent = false
                self.requestRebuildChannelCells()
            }
        }
    }

    /// Build `PlayerViewCell` instances from `device.chnNum`, fill `cellArray`, size horizontal scroll.
    /// 调用方（除初始化外）必须确保此前已停掉 SDK 上的 live / GL consumer，否则 SDK 会持有
    /// 一个野的 `CAEAGLLayer` 指针。
    private func doRebuildChannelCells() {
        // 与 teardown 一致，先禁用隐式动画并显式摘掉每个 `glLayer`，再 removeFromSuperview。
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for cell in cellArray {
            cell.glLayer.contents = nil
            cell.glLayer.removeFromSuperlayer()
        }
        for sub in bgScrollView.subviews {
            sub.removeFromSuperview()
        }
        CATransaction.commit()
        cellArray.removeAll(keepingCapacity: true)

        let count = Self.derivedCellCount(for: device)
        let w = pageWidth
        let h = max(bgScrollView.bounds.height, bounds.height, 1)

        for i in 0 ..< count {
            let cell = PlayerViewCell(frame: CGRect(x: CGFloat(i) * w, y: 0, width: w, height: h))
            bgScrollView.addSubview(cell)
            cellArray.append(cell)
        }

        updateScrollContentSizeAndPaging(pageHeight: h)
    }

    private func updateScrollContentSizeAndPaging(pageHeight: CGFloat) {
        let w = pageWidth
        let n = cellArray.count
        let totalW = w * CGFloat(n)
        bgScrollView.contentSize = CGSize(width: totalW, height: pageHeight)
        // Paging aligns only when visible width equals page width.
        bgScrollView.isPagingEnabled = abs(bgScrollView.bounds.width - w) < 0.5
    }
    
//    override class var layerClass: AnyClass {
//        CAEAGLLayer.self
//    }
//
//    var glLayer: CAEAGLLayer {
//        layer as! CAEAGLLayer
//    }
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupLayer()
//    }
//
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        setupLayer()
//    }
//
//    private func setupLayer() {
//        glLayer.isOpaque = true
//        glLayer.contentsScale = UIScreen.main.scale
//        glLayer.drawableProperties = [
//            kEAGLDrawablePropertyRetainedBacking as String: false,
//            kEAGLDrawablePropertyColorFormat as String: kEAGLColorFormatRGBA8
//        ]
//    }
//
    override func layoutSubviews() {
        super.layoutSubviews()
        bgScrollView.frame = bounds
        let w = pageWidth
        let h = bgScrollView.bounds.height
        guard h > 0, !cellArray.isEmpty else { return }
        for (i, cell) in cellArray.enumerated() {
            cell.frame = CGRect(x: CGFloat(i) * w, y: 0, width: w, height: h)
        }
        updateScrollContentSizeAndPaging(pageHeight: h)
    }
}
