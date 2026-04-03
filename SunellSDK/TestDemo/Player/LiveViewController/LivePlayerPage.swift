//
//  LivePlayerPage.swift
//  TestDemo
//
//  Created by Sunell on 2026/3/25.
//

import UIKit
import SunellSDK

final class LivePlayerPage: UIViewController {

    private let device: SunellDeviceModel
    private var currentChannel: Int32

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
    private var reconnectStatusObserver: NSObjectProtocol?

    init(device: SunellDeviceModel) {
        self.device = device
        currentChannel = 1
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = TKLocalizedString("TK_Live")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        navigationController?.navigationBar.tintColor = .black

        view.addSubview(playAreaView)
        view.addSubview(bottomPlaceholderView)

        playAreaView.bgScrollView.delegate = self

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

        reconnectStatusObserver = NotificationCenter.default.addObserver(
            forName: .sunellDeviceAutoReconnectStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] note in
            self?.handleAutoReconnectStatusNotification(note)
        }
    }

    deinit {
        if let reconnectStatusObserver {
            NotificationCenter.default.removeObserver(reconnectStatusObserver)
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
        guard !playAreaView.cellArray.isEmpty else { return }

        let page = playAreaView.currentPageIndex()
        currentChannel = Int32(channelIdForCellIndex(page))
        didStartLive = true

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.startLive(onPage: page)
            self.updatePageIndicator()
        }
    }

    /// Bottom label: current page (1-based) / total channel pages.
    private func updatePageIndicator() {
        let total = playAreaView.cellArray.count
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

    /// Map `cellArray` index to SDK `channelId` (prefers `device.channels` order).
    private func channelIdForCellIndex(_ index: Int) -> Int {
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
        currentChannel = Int32(chId)
        SunellSDKEntry.liveStart(
            deviceId: device.deviceId,
            channelId: chId,
            streamType: 2,
            isHw: true,
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

        SunellSDKEntry.liveStop(deviceId: device.deviceId, channelId: Int(currentChannel)) { [self] ret in
            if(ret == 0){
                startLive(onPage: page)
            }else {
                print("live stop error")
            }
          
        }
        
    }

    @objc private func backTapped() {
        SunellSDKEntry.liveStop(deviceId: device.deviceId, channelId: Int(currentChannel)){[self] ret in
            if ret == 0 {
                SunellSDKEntry.closeGL()
                navigationController?.popViewController(animated: true)
            }else {
                print("live stop error")
            }
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
