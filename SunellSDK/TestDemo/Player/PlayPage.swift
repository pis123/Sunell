//
//  PlayPage.swift
//  TestDemo
//
//  Created by Sunell on 2026/3/25.
//

import UIKit
import SunellSDK

final class PlayPage: UIViewController {

    private let device: SunellDeviceModel

    init(device: SunellDeviceModel) {
        self.device = device
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = Self.displayName(for: device)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        navigationController?.navigationBar.tintColor = .black

        let liveButton = makeActionButton(title: TKLocalizedString("TK_Live"))
        liveButton.addTarget(self, action: #selector(openLive), for: .touchUpInside)

        let playbackButton = makeActionButton(title: TKLocalizedString("TK_Playback"))
        playbackButton.addTarget(self, action: #selector(openPlayback), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [liveButton, playbackButton])
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            liveButton.heightAnchor.constraint(equalToConstant: 48),
            playbackButton.heightAnchor.constraint(equalToConstant: 48),
            liveButton.widthAnchor.constraint(equalToConstant: 220),
            playbackButton.widthAnchor.constraint(equalToConstant: 220)
        ])
    }

    private func makeActionButton(title: String) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.setTitleColor(.black, for: .normal)
        b.backgroundColor = UIColor(white: 0.92, alpha: 1)
        b.layer.cornerRadius = 8
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        return b
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
        
    }

    @objc private func openLive() {
        let page = LivePlayerPage(device: device)
        navigationController?.pushViewController(page, animated: true)
    }

    @objc private func openPlayback() {
        let page = PlayerBackPage(device: device)
        navigationController?.pushViewController(page, animated: true)
    }

    private static func displayName(for device: SunellDeviceModel) -> String {
        let name = device.deviceName
        if !name.isEmpty { return name }
        let uuid = device.deviceUUID
        if !uuid.isEmpty { return uuid }
        let sn = device.deviceSN
        if !sn.isEmpty { return sn }
        let id = device.deviceId
        if !id.isEmpty { return id }
        return TKLocalizedString("TK_DeviceUntitled")
    }
}
