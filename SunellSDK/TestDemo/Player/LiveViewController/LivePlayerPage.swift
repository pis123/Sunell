//
//  LivePlayerPage.swift
//  TestDemo
//
//  Created by Sunell on 2026/3/25.
//

import UIKit
import SunellSDK
internal import UniformTypeIdentifiers

final class LivePlayerPage: UIViewController {

    private var device: SunellDeviceModel
    private var currentChannel: Int {
        didSet {
            if device.channels.count > 0 {
                if let model = device.channels.first(where: {$0.channelId == currentChannel}) {
                    currentChannelModel = model
                }
            }else {
                currentChannelModel = SunellChannelModel()
                currentChannelModel.deviceId = device.deviceId
                currentChannelModel.channelId = 1
                currentChannelModel.status = device.status
                currentChannelModel.channleName = device.deviceName
            }
            
        }
    }
    private lazy var currentChannelModel : SunellChannelModel = {
//        return device.channels.first ?? SunellChannelModel()
        if device.channels.count > 0 {
            if  let model = device.channels.first(where: {$0.channelId == currentChannel}) {
                return model
            }
        }else {
            let model  = SunellChannelModel()
            model.deviceId = device.deviceId
            model.channelId = 1
            model.status = device.status
            model.channleName = device.deviceName
            return model
        }
        return SunellChannelModel()
    }()
    
    private lazy var playAreaView: PlayerView = {
        let v = PlayerView(frame: .zero, device: device)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .black
        return v
    }()

    private let bottomPlaceholderView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        return v
    }()

    /// 码流为 HD 时 `true`，否则为 SD（默认 `false` 显示 SD）。
    private var isStreamHD: Bool = false
    private var isAudioOn: Bool = false
    /// `getWhiteLightAbility` 返回成功时认为当前通道支持白光灯控制。
    private var supportsWhiteLight: Bool = false

    private lazy var captureButton: UIButton = {
        let b = Self.makeToolbarButton(title: TKLocalizedString("TK_Capture"))
        b.addTarget(self, action: #selector(captureTapped), for: .touchUpInside)
        return b
    }()
    private lazy var ptzButton: UIButton = {
        let b = Self.makeToolbarButton(title: TKLocalizedString("TK_PTZ"))
        b.addTarget(self, action: #selector(ptzTapped), for: .touchUpInside)
        return b
    }()

    private var ptzKeyboardView: PTZKeyboardView?
    private lazy var audioButton: UIButton = {
        let b = Self.makeToolbarButton(title: TKLocalizedString("TK_Mute"))
        b.addTarget(self, action: #selector(audioTapped), for: .touchUpInside)
        return b
    }()
    private lazy var talkButton: UIButton = {
        let b = Self.makeToolbarButton(title: TKLocalizedString("TK_TalkClose"))
        b.addTarget(self, action: #selector(talkTapped), for: .touchUpInside)
        b.setTitle(TKLocalizedString("TK_TalkOpen"), for: .selected)
        return b
    }()
    private lazy var streamButton: UIButton = {
        let b = Self.makeToolbarButton(title: TKLocalizedString("TK_StreamSD"))
        b.addTarget(self, action: #selector(streamTapped), for: .touchUpInside)
        return b
    }()

    private lazy var whiteLightButton: UIButton = {
        let b = Self.makeToolbarButton(title: TKLocalizedString("TK_WhiteLight"))
        b.addTarget(self, action: #selector(whiteLightTapped), for: .touchUpInside)
        return b
    }()
    private lazy var alarmButton: UIButton = {
        let b = Self.makeToolbarButton(title: TKLocalizedString("TK_PlayAlarm"))
        b.addTarget(self, action: #selector(playAlarmTapped), for: .touchUpInside)
        return b
    }()

    private lazy var channelStatusMonitorButton: UIButton = {
        let b = Self.makeToolbarButton(title: TKLocalizedString("TK_ChannelStatusMonitorStart"))
        b.addTarget(self, action: #selector(channelStatusMonitorTapped), for: .touchUpInside)
        b.setTitle(TKLocalizedString("TK_ChannelStatusMonitorStop"), for: .selected)
        b.isSelected = false
        b.titleLabel?.numberOfLines = 1
        b.titleLabel?.adjustsFontSizeToFitWidth = false
        b.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        b.setContentHuggingPriority(.required, for: .horizontal)
        b.setContentCompressionResistancePriority(.required, for: .horizontal)
        return b
    }()

    /// 第一行：截图 / 音频 / 对讲 / 码流 / PTZ。
    private lazy var toolbarRow1: UIStackView = {
        let s = UIStackView(arrangedSubviews: [
            captureButton, audioButton, talkButton, streamButton, ptzButton
        ])
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .horizontal
        s.alignment = .fill
        s.distribution = .fillEqually
        s.spacing = 8
        return s
    }()
    /// 第二行：白光灯、播放报警（位于 PTZ 下一行）。
    private lazy var toolbarRow2: UIStackView = {
        let s = UIStackView(arrangedSubviews: [whiteLightButton, alarmButton])
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .horizontal
        s.alignment = .fill
        s.distribution = .fillEqually
        s.spacing = 8
        return s
    }()
    /// 第三行：通道状态监听（位于白光灯行下方）；按钮靠左，宽度随文案略宽于文字。
    private lazy var toolbarRow3: UIStackView = {
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let s = UIStackView(arrangedSubviews: [channelStatusMonitorButton, spacer])
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .horizontal
        s.alignment = .center
        s.distribution = .fill
        s.spacing = 0
        return s
    }()
    private lazy var toolbarStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [toolbarRow1, toolbarRow2, toolbarRow3])
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .vertical
        s.alignment = .fill
        s.distribution = .fill
        s.spacing = 10
        return s
    }()

    private let pageIndicatorContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        v.layer.cornerRadius = 8
        v.layer.masksToBounds = true
        v.isUserInteractionEnabled = false
        return v
    }()

    private let pageIndicatorLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = .white
        l.textAlignment = .center
        l.text = "0/0"
        return l
    }()

    private var didStartLive = false
    /// 将「对齐 device / 重建 cell + 首播」延后到下一轮 RunLoop，避免在 `layoutSubviews` 同步路径里 `reload`/触发布局，导致重复 `startLive` 进而 GL 崩溃。
    private var deferredLiveBootstrapWorkItem: DispatchWorkItem?
    /// 已执行退出清理（`liveStop` + `closeGL`），避免返回按钮与 `viewDidDisappear` 重复释放。
    private var livePreviewTornDown = false
    /// 因 Scene 进入 inactive/后台而主动停过流，回到前台需要恢复。
    private var suspendedForSceneLifecycle = false
    private var reconnectStatusObserver: NSObjectProtocol?
    private var scenePauseObserver: NSObjectProtocol?
    private var sceneResumeObserver: NSObjectProtocol?
    private var videoOperationObserver: NSObjectProtocol?

    init(device: SunellDeviceModel) {
        self.device = device
        currentChannel = 1
        super.init(nibName: nil, bundle: nil)
    }
    var snaphotPath : String!
    var thumbnailPath : String!
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = TKLocalizedString("TK_Live")
        snaphotPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first?.appending("/snaphot/");
        thumbnailPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first?.appending("/thumbnailPath/");

        // Ensure folders exist so SDK can write images.
        if let snaphotPath {
            try? FileManager.default.createDirectory(atPath: snaphotPath, withIntermediateDirectories: true)
        }
        if let thumbnailPath {
            try? FileManager.default.createDirectory(atPath: thumbnailPath, withIntermediateDirectories: true)
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        navigationController?.navigationBar.tintColor = .black

        view.addSubview(playAreaView)
        view.addSubview(bottomPlaceholderView)
        bottomPlaceholderView.addSubview(toolbarStack)

        playAreaView.bgScrollView.delegate = self
        // 通道数 / 设备实例变化导致 cell 需要物理重建时，先 `liveStop` + `closeGL`，
        // 等 SDK 释放 GL consumer 之后再让 `PlayerView` 拆掉旧 `glLayer`。
        playAreaView.willRebuildCells = { [weak self] proceed in
            self?.tearDownForCellRebuild(proceed: proceed)
        }

        playAreaView.addSubview(pageIndicatorContainer)
        pageIndicatorContainer.addSubview(pageIndicatorLabel)

        let playHeight = UIScreen.main.bounds.width * (3.0 / 4.0)

        NSLayoutConstraint.activate([
            playAreaView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playAreaView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playAreaView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playAreaView.heightAnchor.constraint(equalToConstant: playHeight),

            bottomPlaceholderView.topAnchor.constraint(equalTo: playAreaView.bottomAnchor),
            bottomPlaceholderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomPlaceholderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomPlaceholderView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            toolbarStack.topAnchor.constraint(equalTo: bottomPlaceholderView.safeAreaLayoutGuide.topAnchor, constant: 12),
            toolbarStack.leadingAnchor.constraint(equalTo: bottomPlaceholderView.leadingAnchor, constant: 16),
            toolbarStack.trailingAnchor.constraint(equalTo: bottomPlaceholderView.trailingAnchor, constant: -16),

            pageIndicatorContainer.centerXAnchor.constraint(equalTo: playAreaView.centerXAnchor),
            pageIndicatorContainer.bottomAnchor.constraint(equalTo: playAreaView.bottomAnchor, constant: -12),

            pageIndicatorLabel.topAnchor.constraint(equalTo: pageIndicatorContainer.topAnchor, constant: 6),
            pageIndicatorLabel.leadingAnchor.constraint(equalTo: pageIndicatorContainer.leadingAnchor, constant: 12),
            pageIndicatorLabel.bottomAnchor.constraint(equalTo: pageIndicatorContainer.bottomAnchor, constant: -6),
            pageIndicatorLabel.trailingAnchor.constraint(equalTo: pageIndicatorContainer.trailingAnchor, constant: -12)
        ])

        playAreaView.accessibilityIdentifier = device.deviceId
        playAreaView.bringSubviewToFront(pageIndicatorContainer)
        updatePageIndicator()

        // 进入页面先禁用工具栏，避免视频未真正打开就触发操作导致请求失败。
        setToolbarInteractionEnabled(false)

        reconnectStatusObserver = NotificationCenter.default.addObserver(
            forName: .sunellDeviceAutoReconnectStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] note in
            self?.handleAutoReconnectStatusNotification(note)
        }
        videoOperationObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("sunellSDKVideoOperation"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let dict = notification.object as? [String: Any] else {
                return
            }
            let deviceId = dict["deviceId"] as? String
            let channelId = Self.readChannelId(from: dict)
            let eventId = dict["eventId"] as? Int
            if eventId == 100,
               deviceId == self?.device.deviceId,
               self?.currentChannel == channelId {
                print("打开成功")
                // 白光灯权限等 `getWhiteLightAbility` 回调，先置灰避免误点。
                self?.supportsWhiteLight = false
                self?.setToolbarInteractionEnabled(true)
                self?.getDeviceTalkAndPTZCapcity { [weak self] in
                    self?.applyTalkAndPTZCapabilityToToolbar()
                }
                // 视频播放成功后再请求白光灯能力，有高亮 / 置灰样式。
                self?.refreshWhiteLightPermissionAfterVideoReady()
            }
        }

        scenePauseObserver = NotificationCenter.default.addObserver(
            forName: .sunellSceneWillResignActivePauseVideo,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pauseLiveForSceneResignActive()
        }
        sceneResumeObserver = NotificationCenter.default.addObserver(
            forName: .sunellSceneDidBecomeActiveResumeVideo,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resumeLiveAfterSceneBecomeActive()
        }
        
    }

    /// 切到后台 / 来电遮罩等：停流并关 GL，避免后台仍提交 GPU。
    /// 这里 `liveStop` 回调里仍然需要 `closeGL`，但**不 capture self**，闭包内只持有不可变的
    /// `deviceId` / `channelId` 副本，避免回调被推迟期间控制器进入 deinit 引发竞态。
    private func pauseLiveForSceneResignActive() {
        guard view.window != nil, didStartLive else { return }
        suspendedForSceneLifecycle = true
        setToolbarInteractionEnabled(false)

        // 后台期间 layer 仍在层级里（resume 后会复用），所以这里不 detach，
        // 仅清空一次 contents，避免 SDK 后台仍向旧的 surface 提交。
        let cells = playAreaView.cellArray
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for cell in cells {
            cell.glLayer.contents = nil
        }
        CATransaction.commit()

        let deviceId = device.deviceId
        let channelId = Int(currentChannel)
        SunellSDKEntry.liveStop(deviceId: deviceId, channelId: channelId) { _ in
            SunellSDKEntry.closeGL()
        }
    }

    /// 回到前台：若在直播页且曾因病停流，则重新开流（工具栏仍等 eventId 100 再启用）。
    private func resumeLiveAfterSceneBecomeActive() {
        guard view.window != nil, suspendedForSceneLifecycle else { return }
        suspendedForSceneLifecycle = false
        let page = playAreaView.currentPageIndex()
        startLive(onPage: page)
    }

    /// 与 ObjC / UserInfo 里 `NSNumber` 等类型兼容，避免 `channelId` 取不到导致事件对不上。
    private static func readChannelId(from dict: [String: Any]) -> Int? {
        if let n = dict["channelId"] as? Int { return n }
        if let n = dict["channelId"] as? NSNumber { return n.intValue }
        return nil
    }
    
    // 获取设备的对讲，ptz权限（建议在“视频打开成功”回调后再请求）
    private func getDeviceTalkAndPTZCapcity(completion: (() -> Void)? = nil) {
        let finish: () -> Void = {
            guard let completion else { return }
            if Thread.isMainThread {
                completion()
            } else {
                DispatchQueue.main.async(execute: completion)
            }
        }

        // normal: 未请求/失败；capable: 支持；not_capable: 不支持
        let needRequest = (currentChannelModel.ptzCapacity == SunellDeviceCapacityType_normal)
            || (currentChannelModel.talkCapacity == SunellDeviceCapacityType_normal)
        guard needRequest else {
            finish()
            return
        }

        SunellSDKEntry.getDeviceCapacityWithDeviceId(deviceId: device.deviceId, channelId: currentChannel) { [weak self] result, channelModel in
            guard let self else { return }
            if result == 0 {
                print("获取能力成功")
                if let channelModel {
                    print("channelId:",currentChannelModel.channelId)
                    if currentChannelModel.channelId == channelModel.channelId {
                        currentChannelModel.ptzCapacity = channelModel.ptzCapacity
                        currentChannelModel.talkCapacity = channelModel.talkCapacity
                    }
                }
            } else {
                print("获取能力失败")
            }
            finish()
        }
    }

    private func applyTalkAndPTZCapabilityToToolbar() {
        // 只有在视频已打开成功且工具栏整体启用时才允许点；否则一律置灰禁用
        guard captureButton.isEnabled else {
            talkButton.isEnabled = false
            talkButton.isUserInteractionEnabled = false
            talkButton.alpha = 0.45
            ptzButton.isEnabled = false
            ptzButton.isUserInteractionEnabled = false
            ptzButton.alpha = 0.45
            alarmButton.isEnabled = false
            alarmButton.isUserInteractionEnabled = false
            alarmButton.alpha = 0.45
            applyWhiteLightButtonAppearance()
            return
        }
        
        let talkCapable = (currentChannelModel.talkCapacity == SunellDeviceCapacityType_capable)
        let ptzCapable = (currentChannelModel.ptzCapacity == SunellDeviceCapacityType_capable)

        talkButton.isEnabled = talkCapable
        talkButton.isUserInteractionEnabled = talkCapable
        talkButton.alpha = talkCapable ? 1.0 : 0.45
        if !talkCapable, talkButton.isSelected {
            talkButton.isSelected = false
        }

        ptzButton.isEnabled = ptzCapable
        ptzButton.isUserInteractionEnabled = ptzCapable
        ptzButton.alpha = ptzCapable ? 1.0 : 0.45

        applyWhiteLightButtonAppearance()
        alarmButton.isEnabled = true
        alarmButton.isUserInteractionEnabled = true
        alarmButton.alpha = 1.0
    }

    /// 根据视频是否就绪、`supportsWhiteLight` 刷新白光灯：有权限高亮可点，无权限置灰不可点。
    private func applyWhiteLightButtonAppearance() {
        let videoReady = captureButton.isEnabled
        if !videoReady {
            whiteLightButton.isEnabled = false
            whiteLightButton.isUserInteractionEnabled = false
            Self.styleWhiteLightButton(whiteLightButton, highlighted: false)
            return
        }
        whiteLightButton.isEnabled = supportsWhiteLight
        whiteLightButton.isUserInteractionEnabled = supportsWhiteLight
        Self.styleWhiteLightButton(whiteLightButton, highlighted: supportsWhiteLight)
    }

    /// 仅在视频打开成功（`eventId == 100`）后调用，根据 `getWhiteLightAbilityWithDeviceId` 判断是否有白光灯权限。
    private func refreshWhiteLightPermissionAfterVideoReady() {
        SunellSDKEntry.getWhiteLightAbilityWithDeviceId(deviceId: device.deviceId, channelId: currentChannel) { [weak self] result, json in
            guard let self else { return }
            self.supportsWhiteLight = Self.parseWhiteLightAbilityPermitted(result: result, json: json)
            self.applyWhiteLightButtonAppearance()
        }
    }

    /// `getWhiteLightAbility`：`result == 0` 且 JSON 未明确关闭时视为有权限；可按设备协议扩展字段解析。
    private static func parseWhiteLightAbilityPermitted(result: Int, json: String?) -> Bool {
        guard result == 0 else { return false }
        guard let json, !json.isEmpty,
              let data = json.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return true
        }
        let denyKeys = ["support", "Support", "enable", "Enable", "able", "Able", "WhiteLightEnable", "white_light_enable"]
        for key in denyKeys {
            if let n = root[key] as? Int, n == 0 { return false }
            if let b = root[key] as? Bool, b == false { return false }
        }
        if let n = root["result"] as? Int, n != 0 { return false }
        if let n = root["code"] as? Int, n != 0 { return false }
        if let n = root["WhiteLight"] as? Int, n == 0 { return false }
        if let n = root["white_light"] as? Int, n == 0 { return false }
        return true
    }

    /// 有权限：高亮（描边 + 浅底 + 主题色字）；无权限或未开流：置灰。
    private static func styleWhiteLightButton(_ b: UIButton, highlighted: Bool) {
        if highlighted {
            b.alpha = 1.0
            b.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.14)
            b.layer.borderColor = UIColor.systemBlue.cgColor
            b.layer.borderWidth = 1.5
            b.setTitleColor(.systemBlue, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        } else {
            b.alpha = 0.45
            b.backgroundColor = .white
            b.layer.borderColor = UIColor.black.withAlphaComponent(0.22).cgColor
            b.layer.borderWidth = 1
            b.setTitleColor(.label.withAlphaComponent(0.55), for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        }
    }

    private static func applyChannelStatusMonitorTitles(to button: UIButton) {
        button.setTitle(TKLocalizedString("TK_ChannelStatusMonitorStart"), for: .normal)
        button.setTitle(TKLocalizedString("TK_ChannelStatusMonitorStop"), for: .selected)
        button.setTitleColor(.black, for: .selected)
    }

    /// 工具栏按钮：禁用时置灰且不可点；启用必须等到视频真正播放成功回调（eventId == 100）。
    private func setToolbarInteractionEnabled(_ enabled: Bool) {
        let alwaysButtons: [UIButton] = [captureButton, audioButton, streamButton, alarmButton, channelStatusMonitorButton]
        for b in alwaysButtons {
            b.isEnabled = enabled
            b.isUserInteractionEnabled = enabled
            b.alpha = enabled ? 1.0 : 0.45
        }

        if !enabled {
            channelStatusMonitorButton.isSelected = false
            Self.applyChannelStatusMonitorTitles(to: channelStatusMonitorButton)
            talkButton.isEnabled = false
            talkButton.isUserInteractionEnabled = false
            talkButton.alpha = 0.45
            ptzButton.isEnabled = false
            ptzButton.isUserInteractionEnabled = false
            ptzButton.alpha = 0.45
            applyWhiteLightButtonAppearance()
        } else {
            // enabled==true 时，PTZ/对讲是否可点交给能力值控制（能力未取到时会先置灰，取到后再刷新）
            applyTalkAndPTZCapabilityToToolbar()
            Self.applyChannelStatusMonitorTitles(to: channelStatusMonitorButton)
        }
    }

    private func cancelPendingDeferredLiveBootstrap() {
        deferredLiveBootstrapWorkItem?.cancel()
        deferredLiveBootstrapWorkItem = nil
    }

    /// 离开直播页或 `deinit` 时必须停流并关 GL；仅依赖导航栏返回会在「侧滑返回」等路径下漏调，导致内存长期不降。
    ///
    /// 关键时序约束：
    /// 1. 主线程同步把所有 `cell.glLayer` 从层级里摘除并清空 `contents`，让它们立刻脱离即将进入
    ///    `CATransaction.commit()` 的视图树。这是规避 `LayerAnimation::unref` 崩溃的关键 ——
    ///    SDK render_thread 会在 `CAEAGLLayer` 上修改属性 / 触发隐式动画，若摘除前这层就被
    ///    `CA::Layer::destroy` 销毁，commit 阶段会过度释放挂在 layer 上的 animation。
    /// 2. 之后再异步 `liveStop`/`closeGL`。回调里**不再 capture `self`**，确保即使控制器先 dealloc
    ///    了，SDK 侧 GL consumer / 解码表面仍能完整释放。
    ///
    /// - Parameter completion: 在 `liveStop` 回调里执行完 `closeGL` 之后调用（已在主线程）；未开过流或已释放过时也会异步到主线程回调。
    private func tearDownLivePreviewIfNeeded(completion: (() -> Void)? = nil) {
        cancelPendingDeferredLiveBootstrap()
        let finish: () -> Void = {
            guard let completion else { return }
            if Thread.isMainThread {
                completion()
            } else {
                DispatchQueue.main.async(execute: completion)
            }
        }

        guard !livePreviewTornDown else {
            finish()
            return
        }
        guard didStartLive else {
            livePreviewTornDown = true
            detachAllGLLayersSynchronously()
            finish()
            return
        }
        livePreviewTornDown = true
        suspendedForSceneLifecycle = false
        setToolbarInteractionEnabled(false)
        playAreaView.bgScrollView.delegate = nil

        detachAllGLLayersSynchronously()

        let deviceId = device.deviceId
        let channelId = Int(currentChannel)
        let needTalkOff = talkButton.isSelected

        if needTalkOff {
            print("talkSwitchWithDeviceId1")
            SunellSDKEntry.talkSwitchWithDeviceId(deviceId: deviceId, channelId: channelId, isOpen: false) { _ in
                print("talkSwitchWithDeviceId2")
            }
        }
        print("talkSwitchWithDeviceId3")
        SunellSDKEntry.liveStop(deviceId: deviceId, channelId: channelId) { _ in
            print("talkSwitchWithDeviceId4")
            SunellSDKEntry.closeGL()
            finish()
        }
    }

    /// 主线程同步将所有 `PlayerViewCell.glLayer` 摘下并清空 `contents`，并禁用隐式动画。
    /// 必须在调用 SDK `liveStop` / `closeGL` 之前执行，断开 SDK render_thread 与可见 layer 树的耦合。
    private func detachAllGLLayersSynchronously() {
        let cells = playAreaView.cellArray
        guard !cells.isEmpty else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for cell in cells {
            cell.glLayer.contents = nil
            cell.glLayer.removeFromSuperlayer()
        }
        CATransaction.commit()
    }

    /// `PlayerView` 即将物理重建 cell（通道数 / 设备实例变化）时被调用。
    /// 必须先停掉当前 SDK live + GL consumer，再让 `PlayerView` 拆 cell；
    /// 完成后重置 `didStartLive` / `livePreviewTornDown`，让 `viewDidLayoutSubviews`
    /// 能够再次自动 bootstrap 新的 cell。
    private func tearDownForCellRebuild(proceed: @escaping () -> Void) {
        cancelPendingDeferredLiveBootstrap()
        suspendedForSceneLifecycle = false
        setToolbarInteractionEnabled(false)

        detachAllGLLayersSynchronously()

        let resume: () -> Void = { [weak self] in
            // 旧 cell 被丢弃后 GL consumer 已经释放，允许下一轮 layout 再次 `startLive`。
            self?.didStartLive = false
            self?.livePreviewTornDown = false
            proceed()
        }

        guard didStartLive else {
            resume()
            return
        }

        let deviceId = device.deviceId
        let channelId = Int(currentChannel)
        let needTalkOff = talkButton.isSelected

        if needTalkOff {
            SunellSDKEntry.talkSwitchWithDeviceId(deviceId: deviceId, channelId: channelId, isOpen: false) { _ in }
        }
        SunellSDKEntry.liveStop(deviceId: deviceId, channelId: channelId) { _ in
            SunellSDKEntry.closeGL()
            resume()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 推入截图预览等子页时 `isMovingFromParent` 为 false，不会误停流。
        // 选择 `viewWillDisappear` 而非 `viewDidDisappear`：此时 view 仍在窗口，所有 `glLayer`
        // 还在层级里，可以同步从 superlayer 上摘下，避免它们在后续 `CATransaction.commit` 阶段
        // 与 SDK render_thread 抢 layer 状态，从而消除 `LayerAnimation::unref` 崩溃栈。
        let leavingStack = isMovingFromParent || isBeingDismissed
            || (navigationController?.isBeingDismissed == true)
        if leavingStack {
            tearDownLivePreviewIfNeeded()
        }
    }

    deinit {
        print("\nLivePlayerPage deinit\n")
        cancelPendingDeferredLiveBootstrap()
        // 控制器已被释放，不再发起新的异步 `liveStop`（捕获的 self 会立即变为 nil，且
        // SDK 回调里再调 `closeGL` 与即将销毁的 view 树时序竞争）。正常路径上
        // `backTapped` / `viewWillDisappear` 已经走过 teardown；这里仅在异常路径下
        // 同步关一次 GL，确保 SDK 侧不会继续写已销毁的 `CAEAGLLayer`。
        if !livePreviewTornDown {
            livePreviewTornDown = true
            SunellSDKEntry.closeGL()
        }
        if let reconnectStatusObserver {
            NotificationCenter.default.removeObserver(reconnectStatusObserver)
        }
        if let scenePauseObserver {
            NotificationCenter.default.removeObserver(scenePauseObserver)
        }
        if let sceneResumeObserver {
            NotificationCenter.default.removeObserver(sceneResumeObserver)
        }
        if let videoOperationObserver {
            NotificationCenter.default.removeObserver(videoOperationObserver)
        }
    }

    /// On auto-reconnect success, resume live preview.
    private func handleAutoReconnectStatusNotification(_ note: Notification) {
        guard let info = note.userInfo,
              let deviceId = info["deviceId"] as? String,
              deviceId == device.deviceId
        else { return }

        let status = info["status"] as? Int
        if(status == 1){
            // Device back online.
            let page = playAreaView.currentPageIndex()
            startLive(onPage: page)
        }else {
            // ...
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updatePageIndicator()

        guard !didStartLive else { return }
        guard playAreaView.bounds.width > 0, playAreaView.bounds.height > 0 else { return }

        scheduleDeferredLiveBootstrapFromLayoutIfNeeded()
    }

    /// 延后到下一轮主线程队列：先 `syncPlayAreaCells`，再择机 `startLive`，避免在当前 layout 同步链里触发 `reloadChannelCells`/重复开播。
    private func scheduleDeferredLiveBootstrapFromLayoutIfNeeded() {
        guard !didStartLive else { return }
        deferredLiveBootstrapWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.deferredLiveBootstrapWorkItem = nil
            self.performDeferredLiveBootstrapFromLayout()
        }
        deferredLiveBootstrapWorkItem = work
        DispatchQueue.main.async(execute: work)
    }

    private func performDeferredLiveBootstrapFromLayout() {
        guard !didStartLive else { return }
        guard playAreaView.bounds.width > 0, playAreaView.bounds.height > 0 else { return }

        syncPlayAreaCellsWithDevice()

        let expectedCells = expectedPlayCellCount()
        guard expectedCells > 0, !playAreaView.cellArray.isEmpty else { return }

        let lastPageIndex = max(0, playAreaView.cellArray.count - 1)
        let page = min(max(0, playAreaView.currentPageIndex()), lastPageIndex)
        currentChannel = channelIdForCellIndex(page)
        didStartLive = true

        setToolbarInteractionEnabled(false)
        startLive(onPage: page)
        updatePageIndicator()
    }

    /// 与 `PlayerView` 一致：`chnNum==0` 时视为未上报通道数，按单路 1 窗（不区分 `devType`）。
    private func expectedPlayCellCount() -> Int {
        let raw = max(0, Int(device.chnNum))
        if raw == 0 {
            return 1
        }
        return raw
    }

    /// 列表页 `device` 可能在连接后被替换或原地补全字段；保证预览区 cell 数量与当前模型一致。
    private func syncPlayAreaCellsWithDevice() {
        let expected = expectedPlayCellCount()
        guard expected > 0 else { return }

        if playAreaView.device !== device {
            playAreaView.device = device
            return
        }
        if playAreaView.cellArray.count != expected {
            playAreaView.reloadChannelCellsFromDevice()
        }
    }

    /// Bottom label: current page (1-based) / total channel pages。
    /// `chnNum == 0` 单路补窗时固定可按 `1/1` 显示（避免早期布局 `cellArray` 仍为空出现 `0/0`）。
    private func updatePageIndicator() {
        var total = playAreaView.cellArray.count
        if total == 0, Int(device.chnNum) == 0 {
            total = 1
        }
        guard total > 0 else {
            pageIndicatorLabel.text = "0/0"
            pageIndicatorContainer.isHidden = true
            return
        }
        pageIndicatorContainer.isHidden = false
        let idx = playAreaView.currentPageIndex()
        let current = min(max(0, idx), total - 1) + 1
        pageIndicatorLabel.text = "\(current)/\(total)"
    }

    /// Map `cellArray` index to SDK `channelId` (prefers `device.channels` order)。
    /// 未上报 `chnNum`（0，单 cell 补位 / 与空 `cellArray` 对应）时固定播通道 `1`。
    private func channelIdForCellIndex(_ index: Int) -> Int {
        if Int(device.chnNum) == 0 {
            return 1
        }
        if let list = device.channels as? [SunellChannelModel], index >= 0, index < list.count {
            return Int(list[index].channelId)
        }
        if let arr = device.channels as? NSArray, index >= 0, index < arr.count {
            if let ch = arr.object(at: index) as? SunellChannelModel {
                return Int(ch.channelId)
            }
        }
        return index + 1
    }
   
    private func startLive(onPage page: Int) {
        guard page >= 0, page < playAreaView.cellArray.count else { return }
        let chId = channelIdForCellIndex(page)
        let cell = playAreaView.cellArray[page]
        currentChannel = chId
        setToolbarInteractionEnabled(false)
        SunellSDKEntry.liveStart(
            deviceId: device.deviceId,
            channelId: chId,
            streamType: 2,
            isHw: false,
            caLayer: cell.glLayer) { ret in
                if ret >= 0 { // >= 0: live start API succeeded.
                    print("start Live success");
                }else {
                    print("start Live error");
                }
            }
       
    }

    private func switchLiveToVisiblePageIfNeeded() {
        let page = playAreaView.currentPageIndex()
        updatePageIndicator()
        guard page >= 0, page < playAreaView.cellArray.count else { return }
        let chId = channelIdForCellIndex(page)
        if Int32(chId) == currentChannel { return }

        setToolbarInteractionEnabled(false)
        if talkButton.isSelected {
            print("switchLiveToVisiblePageIfNeeded1")
            SunellSDKEntry.talkSwitchWithDeviceId(deviceId: device.deviceId, channelId:currentChannel, isOpen: false) { result in
                self.talkButton.isSelected.toggle()
                print("switchLiveToVisiblePageIfNeeded2")
            }
        }
        print("switchLiveToVisiblePageIfNeeded3")
        SunellSDKEntry.liveStop(deviceId: device.deviceId, channelId: Int(currentChannel)) { [weak self] ret in
            print("switchLiveToVisiblePageIfNeeded4")
            guard let self else { return }
            if ret == 0 {
                self.startLive(onPage: page)
            } else {
                print("live stop error")
            }
        }
        
    }

    @objc private func backTapped() {
        navigationItem.leftBarButtonItem?.isEnabled = false
        tearDownLivePreviewIfNeeded { [weak self] in
            guard let self else { return }
            guard self.navigationController?.topViewController === self else { return }
            self.navigationController?.popViewController(animated: true)
        }
    }

    @objc private func captureTapped() {
        print("capture tapped")
        let str = "capture";
        let imageFile = (snaphotPath as NSString).appendingPathComponent("\(str)_\(currentChannel).jpg")
        
        SunellSDKEntry.captureImageWithDeviceId(deviceId: device.deviceId, channelId: currentChannel, path: imageFile) { result in
            
            if result == 0 {
                print("capture Image success")
                SunellAlertView.show(title: "view Capture Image", message: "", onConfirm: { [weak self] in
                    print("jump view Capture Image")
                    guard let self = self else { return }
                    let page = SunellImageViewPage(imageFilePath: imageFile)
                    self.navigationController?.pushViewController(page, animated: true)
                })
            }else {
                print("capture Image failed")
            }
        }
    }

    @objc private func ptzTapped() {
        SunellSDKEntry.openPTZWithDeivceId(deviceId: device.deviceId, channelId: currentChannel) { result in
            if result == 0{
                // open success
                print("ptz open success")
            }else {
                // open failed
                print("ptz open failed")
            }
        }
        if let v = ptzKeyboardView {
            v.animateOut { [weak self] in
                self?.ptzKeyboardView?.removeFromSuperview()
                self?.ptzKeyboardView = nil
            }
            return
        }

        let items: [PTZKeyboardView.Direction: PTZKeyboardView.Item] = [
            .up: .init(key: "TK_PTZ_Up"),
            .upRight: .init(key: "TK_PTZ_UpRight"),
            .right: .init(key: "TK_PTZ_Right"),
            .downRight: .init(key: "TK_PTZ_DownRight"),
            .down: .init(key: "TK_PTZ_Down"),
            .downLeft: .init(key: "TK_PTZ_DownLeft"),
            .left: .init(key: "TK_PTZ_Left"),
            .upLeft: .init(key: "TK_PTZ_UpLeft")
        ]

        let v = PTZKeyboardView(items: items)
       
        v.onTapItem = { title in
//            PTZ_UP = 1,        //向上
//            PTZ_DOWN = 2,      //向下
//            PTZ_LEFT = 3,      //左
//            PTZ_RIGHT = 4,     //右
//            PTZ_LEFT_UP = 5,   //左上
//            PTZ_LEFT_DOWN = 6, //左下
//            PTZ_RIGHT_UP = 7,  //右上
//            PTZ_RIGHT_DOWN = 8, //右下
            var optionArrowType = 0
            switch title {
            case TKLocalizedString("TK_PTZ_Up"):
              print("PTZ:", title)
                optionArrowType = 1
            case TKLocalizedString("TK_PTZ_UpRight"):
                optionArrowType = 7
            case TKLocalizedString("TK_PTZ_Right"):
                optionArrowType = 4
            case TKLocalizedString("TK_PTZ_DownRight"):
                optionArrowType = 8
            case TKLocalizedString("TK_PTZ_Down"):
                optionArrowType = 2
            case TKLocalizedString("TK_PTZ_DownLeft"):
                optionArrowType = 6
            case TKLocalizedString("TK_PTZ_Left"):
                optionArrowType = 3
            case TKLocalizedString("TK_PTZ_UpLeft"):
                optionArrowType = 5
            default:
                print("other")
            }
            
            SunellSDKEntry.operationPTZWithDeviceId(
                deviceId: self.device.deviceId,
                channelId: self.currentChannel,
                arrowType: optionArrowType
            ) { result in
                
                if result == 0 {
                    DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + 0.8) {
                        SunellSDKEntry.stopPTZWithDeviceId(
                            deviceId: self.device.deviceId,
                            channelId: self.currentChannel
                        ) { stopResult in
                            if stopResult == 0 {
                                // success
                            }
                        }
                    }
                }
            }
            
        }
        
        
        
        v.onClose = { [weak self] in
            guard let self, let v = self.ptzKeyboardView else { return }
            v.animateOut { [weak self] in
                self?.ptzKeyboardView?.removeFromSuperview()
                self?.ptzKeyboardView = nil
            }
        }
        view.addSubview(v)
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: view.topAnchor),
            v.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            v.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            v.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        ptzKeyboardView = v
        v.animateIn()
    }

    @objc private func audioTapped() {
        isAudioOn.toggle()
        audioButton.setTitle(
            isAudioOn ? TKLocalizedString("TK_Audio") : TKLocalizedString("TK_Mute"),
            for: .normal
        )
        audioButton.isEnabled = false
        SunellSDKEntry.audioSwitchWithDeviceId(deviceId: device.deviceId, channelId: currentChannel, isOpen: isAudioOn) { result in
            self.audioButton.isEnabled = true
            if result == 0 {
                print("audio option success");
            }else {
                print("audio option failed");
            }
        }
    }

    @objc private func talkTapped() {
        print("talk tapped")
        talkButton.isEnabled = false
        talkButton.isSelected.toggle()
        SunellSDKEntry.talkSwitchWithDeviceId(deviceId: device.deviceId, channelId: currentChannel, isOpen: talkButton.isSelected) { result in
            self.talkButton.isEnabled = true
            if result == 0 {
                print("talk option success");
            }else {
                print("talk option failed");
            }
        }
    }

    @objc private func streamTapped() {
        isStreamHD.toggle()
        streamButton.setTitle(
            isStreamHD ? TKLocalizedString("TK_StreamHD") : TKLocalizedString("TK_StreamSD"),
            for: .normal
        )
        SunellSDKEntry.qualityAdjustmentWithDeviceId(deviceId: device.deviceId, channelId: currentChannel, qualityType: isStreamHD ? 1 : 2) { result in
            if result == 0 {
                print("change stream option Success")
            }else {
                print("change stream option failed")
            }
        }
    }

    @objc private func channelStatusMonitorTapped() {
        channelStatusMonitorButton.isSelected.toggle()
        if channelStatusMonitorButton.isSelected {
            print("通道状态监听已开启")
            SunellSDKEntry.startDeviceChannelAlarmMonitoring(deviceId: device.deviceId)
        } else {
            print("通道状态监听已关闭")
            SunellSDKEntry.stopDeviceChannelAlarmMonitoring(deviceId: device.deviceId)
        }
    }

    @objc private func whiteLightTapped() {
        guard supportsWhiteLight else { return }
        whiteLightButton.isEnabled = false
        SunellSDKEntry.getWhiteLightSwitchParamWithDeviceId(deviceId: device.deviceId, channelId: currentChannel) { [weak self] result, json in
            guard let self else { return }
            let reenable: () -> Void = {
                self.applyWhiteLightButtonAppearance()
            }
            guard result == 0, let json, !json.isEmpty else {
                print("white light get param failed, ret=\(result)")
                reenable()
                return
            }
            Self.toggleWhiteLightInParamJSON(json) { toggledJson in
                guard let toggledJson else {
                    DispatchQueue.main.async {
                        print("white light: could not derive toggle from JSON")
                        reenable()
                    }
                    return
                }
                SunellSDKEntry.setWhiteLightSwitchParamWithDeviceId(
                    deviceId: self.device.deviceId,
                    channelId: self.currentChannel,
                    paramJson: toggledJson
                ) { setRet in
                    DispatchQueue.main.async {
                        print("white light set ret=\(setRet)")
                        reenable()
                    }
                }
            }
        }
    }

    @objc private func playAlarmTapped() {
        alarmButton.isEnabled = false
        SunellSDKEntry.getAudioAlarmInfoWithDeviceId(deviceId: device.deviceId, channelId: currentChannel) { [weak self] result, retJsonStr in
            guard let self else { return }
            let reenableAlarm: () -> Void = {
                let on = self.captureButton.isEnabled
                self.alarmButton.isEnabled = on
                self.alarmButton.isUserInteractionEnabled = on
            }
            defer { reenableAlarm() }

            guard result == 0, let json = retJsonStr, !json.isEmpty else {
                print("alarmAudio: failed result=\(result) json=\(retJsonStr ?? "nil")")
                return
            }
            print("alarmAudio:", json)
            do {
                let parsed = try AudioAlarmInfoJSONParser.parse(json)
                let files = parsed.audioAlarmParam.audioFileList
                let listVC = AudioAlarmFileListViewController(items: files, delegate: self)
                let nav = UINavigationController(rootViewController: listVC)
                nav.modalPresentationStyle = .pageSheet
                if #available(iOS 15.0, *) {
                    if let sheet = nav.sheetPresentationController {
                        sheet.detents = [.medium(), .large()]
                        sheet.prefersGrabberVisible = true
                    }
                }
                self.present(nav, animated: true)
            } catch {
                print("alarmAudio JSON parse error:", error)
            }
        }
    }

    /// 在设备返回的 JSON 上翻转开关类字段并序列化回字符串；字段名按常见协议依次尝试，否则取首个 0/1 整型键。
    private static func toggleWhiteLightInParamJSON(_ json: String, completion: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = json.data(using: .utf8),
                  var root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            let priorityKeys = [
                "WhiteLightSwitch", "white_light_switch", "WhiteLightState", "white_light_state",
                "enable", "Enable", "switch", "Switch", "state", "State"
            ]
            var changed = false
            for key in priorityKeys {
                if let v = root[key] as? Int {
                    root[key] = v == 0 ? 1 : 0
                    changed = true
                    break
                }
                if let v = root[key] as? Bool {
                    root[key] = !v
                    changed = true
                    break
                }
            }
            if !changed {
                for (k, v) in root {
                    if let n = v as? Int, n == 0 || n == 1 {
                        root[k] = n == 0 ? 1 : 0
                        changed = true
                        break
                    }
                }
            }
            guard changed,
                  JSONSerialization.isValidJSONObject(root),
                  let out = try? JSONSerialization.data(withJSONObject: root, options: []),
                  let outStr = String(data: out, encoding: .utf8)
            else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            DispatchQueue.main.async { completion(outStr) }
        }
    }

    private static func makeToolbarButton(title: String) -> UIButton {
        let b = UIButton(type: .custom)
        b.setTitle(title, for: .normal)
        b.setTitleColor(.black, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        b.titleLabel?.adjustsFontSizeToFitWidth = true
        b.titleLabel?.minimumScaleFactor = 0.5
        b.titleLabel?.textAlignment = .center
        b.layer.borderColor = UIColor.black.cgColor
        b.layer.borderWidth = 1
        b.layer.cornerRadius = 5
        b.clipsToBounds = true
        b.translatesAutoresizingMaskIntoConstraints = false
        b.contentEdgeInsets = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        return b
    }
}

// MARK: - AudioAlarmFileListViewControllerDelegate

extension LivePlayerPage: AudioAlarmFileListViewControllerDelegate {

    func audioAlarmFileList(_ controller: AudioAlarmFileListViewController, didSelect file: AudioAlarmFileItem) {
        controller.dismiss(animated: true) { [weak self] in
            self?.playAudioAlarmUsingSDK(file: file)
        }
    }

    private func playAudioAlarmUsingSDK(file: AudioAlarmFileItem) {
        SunellSDKEntry.playAudioAlarmWithDeviceId(
            deviceId: device.deviceId,
            channelId: currentChannel,
            displayId: file.audioFileId,
            playNum: 2
        ) { result in
            print("playAudioAlarm displayId=\(file.audioFileId) playNum=\(file.audioDisplayNum) ret=\(result)")
        }
    }
}

// MARK: - UIScrollViewDelegate

extension LivePlayerPage: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updatePageIndicator()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        switchLiveToVisiblePageIfNeeded()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            switchLiveToVisiblePageIfNeeded()
        }
    }
}
